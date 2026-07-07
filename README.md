[![Current Version](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/release.svg)](https://github.com/simons-containers/distroless-postgres/pkgs/container/distroless-postgres) [![Tags](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/tags.svg)](https://github.com/simons-containers/distroless-postgres/pkgs/container/distroless-postgres) <br> ![Current Size](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/size.svg) ![Wasted Size](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/wasted.svg) ![Efficiency](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/efficiency.svg) <br> ![Critical](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/critical.svg) ![High](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/high.svg) ![Medium](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/medium.svg) ![Low](https://raw.githubusercontent.com/simons-containers/distroless-postgres/badges/.badges/main/low.svg) <br> [![Publish Workflow](https://img.shields.io/github/actions/workflow/status/simons-containers/distroless-postgres/deploy.yaml?label=Publish%20Workflow&logo=github)](https://github.com/simons-containers/distroless-postgres/actions/workflows/deploy.yaml) [![Update Workflow](https://img.shields.io/github/actions/workflow/status/simons-containers/distroless-postgres/update-versions.yaml?label=Update%20Workflow&logo=github)](https://github.com/simons-containers/distroless-postgres/actions/workflows/update-versions.yaml)

# Distroless PostgreSQL container

Bare-bones distroless PostgreSQL container image.

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

- **no-sh-popen-shim** - LD_PRELOAD shim that replaces popen with a version that doesn't require a posix sh.  
  https://github.com/simons-containers/no-sh-popen-shim
