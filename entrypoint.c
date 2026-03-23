#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <dirent.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>

#define POSTGRES_UID 1000
#define POSTGRES_GID 1000

static int file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

static int is_sql_file(const char *name) {
    size_t len = strlen(name);
    return (len > 4 && strcmp(name + len - 4, ".sql") == 0);
}

static int is_conf_file(const char *name) {
    size_t len = strlen(name);
    return (len > 5 && strcmp(name + len - 5, ".conf") == 0);
}

static int is_regular_file(const char *path) {
    struct stat st;
    return stat(path, &st) == 0 && S_ISREG(st.st_mode);
}

static void drop_privileges() {
    if (setgid(POSTGRES_GID) != 0) {
        perror("setgid");
        exit(1);
    }
    if (setuid(POSTGRES_UID) != 0) {
        perror("setuid");
        exit(1);
    }
}

static void run_initdb(const char *pgdata) {
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork initdb");
        exit(1);
    }

    if (pid == 0) {
        execlp("initdb", "initdb",
               "-D", pgdata,
               "--locale=en_US.utf8",
               NULL);
        perror("exec initdb");
        exit(1);
    }

    int status;
    waitpid(pid, &status, 0);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        fprintf(stderr, "[entrypoint] initdb failed\n");
        exit(1);
    }
}

static void run_sql_files(const char *pgdata) {
    DIR *d = opendir("/initdb");
    if (!d)
        return;

    struct dirent *ent;

    while ((ent = readdir(d)) != NULL) {
        if (!is_sql_file(ent->d_name))
            continue;

        char path[512];
        snprintf(path, sizeof(path), "/initdb/%s", ent->d_name);

        if (!is_regular_file(path))
            continue;

        fprintf(stderr, "[entrypoint] Running %s\n", path);

        int pipefd[2];
        pipe(pipefd);

        pid_t pid = fork();
        if (pid < 0) {
            perror("fork");
            exit(1);
        }

        if (pid == 0) {
            close(pipefd[1]);
            dup2(pipefd[0], STDIN_FILENO);

            execlp("postgres", "postgres",
                   "--single",
                   "-D", pgdata,
                   "postgres",
                   NULL);

            perror("exec postgres --single");
            exit(1);
        }

        close(pipefd[0]);

        FILE *fp = fopen(path, "r");
        if (!fp) {
            perror("fopen");
            exit(1);
        }

        char buf[4096];
        size_t n;
        while ((n = fread(buf, 1, sizeof(buf), fp)) > 0)
            write(pipefd[1], buf, n);

        fclose(fp);
        close(pipefd[1]);

        int status;
        waitpid(pid, &status, 0);

        if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
            fprintf(stderr, "[entrypoint] SQL load failed: %s\n", path);
            exit(1);
        }
    }

    closedir(d);
}

static void copy_conf_files(const char *pgdata) {
    DIR *d = opendir("/initdb");
    if (!d)
        return;

    struct dirent *ent;

    while ((ent = readdir(d)) != NULL) {
        if (!is_conf_file(ent->d_name))
            continue;

        char src[512], dst[512];
        snprintf(src, sizeof(src), "/initdb/%s", ent->d_name);
        snprintf(dst, sizeof(dst), "%s/%s", pgdata, ent->d_name);

        if (!is_regular_file(src))
            continue;

        fprintf(stderr, "[entrypoint] Installing conf: %s -> %s\n", src, dst);

        int in = open(src, O_RDONLY);
        if (in < 0) {
            perror("open src");
            exit(1);
        }

        int out = open(dst, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (out < 0) {
            perror("open dst");
            exit(1);
        }

        char buf[4096];
        ssize_t n;
        while ((n = read(in, buf, sizeof(buf))) > 0)
            write(out, buf, n);

        close(in);
        close(out);

        chown(dst, POSTGRES_UID, POSTGRES_GID);
    }

    closedir(d);
}

int main(int argc, char **argv, char **envp) {
    const char *pgdata = "/var/lib/postgresql/data";

    char version_file[512];
    snprintf(version_file, sizeof(version_file), "%s/PG_VERSION", pgdata);

    if (!file_exists(version_file)) {
        fprintf(stderr, "[entrypoint] Initializing cluster...\n");

        mkdir("/var/lib/postgresql", 0755);
        mkdir(pgdata, 0700);

        chown("/var/lib/postgresql", POSTGRES_UID, POSTGRES_GID);
        chown(pgdata, POSTGRES_UID, POSTGRES_GID);

        drop_privileges();

        run_initdb(pgdata);
        run_sql_files(pgdata);
        copy_conf_files(pgdata);

    } else {
        drop_privileges();
        copy_conf_files(pgdata);
    }

    fprintf(stderr, "[entrypoint] Starting postgres...\n");
    execve("/usr/bin/postgres", argv, envp);
    perror("execve postgres");
    return 1;
}

