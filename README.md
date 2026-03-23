# Distroless PostgreSQL container

Bare-bones distroless PostgreSQL container image.

## Building

| Build Arg | Description |
|---|---|
| `POSTGRES_VERSION` | Version of PostgreSQL to use
| `ZLIB_VERSION` | Version of zlib to use
| `OPENSSL_VERSION` | Version of openssl to use
| `ICU_VERSION` | Version of icu to use
| `READLINE_VERSION` | Version of readline to use
| `NCURSES_VERSION` | Version of ncurses to use
| `DASH_VERSION` | Version of dash to use

Build container using build-args from versions.yaml:

```bash
docker build -t postgres $(yq -r 'to_entries | .[] | "--build-arg \(.key | ascii_upcase)_VERSION=\(.value)"' versions.yaml) -f Containerfile .
```

## License

Repository contents (e.g., `Containerfile`, build scripts, and configuration) are licensed under the **MIT License**.

Software included in built container images (such as **PostgreSQL**, **readline**, **zlib**, etc...) are provided under their respective upstream licenses and are not covered by the MIT license for this repository.

## Acknowledgements

This project depends on several upstream components that provide essential runtime libraries, toolchains, and platform capabilities:

- **PostgreSQL** – The World's Most Advanced Open Source Relational Database  
  https://postgresql.org

- **zlib** – A foundational compression library implementing the DEFLATE algorithm, widely used across system software for efficient data compression and decompression.  
  https://zlib.net/

- **OpenSSL** – A comprehensive cryptographic library offering TLS, hashing, and encryption primitives required for secure communication and data integrity.  
  https://www.openssl.org/

- **ICU** – The International Components for Unicode library, providing robust Unicode handling, locale data, and globalization support for text processing.  
  https://icu.unicode.org/

- **readline** - The GNU Readline library provides a set of functions for use by applications that allow users to edit command lines as they are typed in.  
  https://tiswww.case.edu/php/chet/readline/rltop.html

- **ncurses** - The ncurses (new curses) library is a free software emulation of curses in System V Release 4.0 (SVr4), and more.  
  https://invisible-island.net/ncurses/

- **dash** - DASH is a POSIX-compliant implementation of /bin/sh that aims to be as small as possible.    
  http://gondor.apana.org.au/~herbert/dash/
