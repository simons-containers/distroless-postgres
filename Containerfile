FROM archlinux:base-devel-20260308.0.497099 AS builder

ARG POSTGRES_VERSION
ARG GCC_VERSION
ARG ZLIB_VERSION
ARG OPENSSL_VERSION
ARG ICU_VERSION
ARG READLINE_VERSION
ARG NCURSES_VERSION
ARG DASH_VERSION

ARG POSTGRES_SOURCE=https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz
ARG GCC_SOURCE=https://mirrors.ocf.berkeley.edu/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
ARG ZLIB_SOURCE=https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
ARG GNU_SOURCES=https://ftp.gnu.org/pub/gnu
ARG OPENSSL_SOURCE=https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
ARG ICU_SOURCE=https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION}/icu4c-${ICU_VERSION}-sources.tgz
ARG NCURSES_SOURCE=${GNU_SOURCES}/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
ARG READLINE_SOURCE=${GNU_SOURCES}/readline/readline-${READLINE_VERSION}.tar.gz
ARG DASH_SOURCE=http://gondor.apana.org.au/~herbert/dash/files/dash-${DASH_VERSION}.tar.gz

RUN pacman -Sy --noconfirm python >/dev/null

WORKDIR /build/gcc
RUN curl --silent --show-error --location --output gcc.tar.gz \
    "${GCC_SOURCE}" \
    && tar xf gcc.tar.gz --strip-components=1 \
    && ./contrib/download_prerequisites \
    && mkdir build && cd build \
    && ../configure \
        --prefix=/usr \
        --libdir=/usr/lib \
        --libexecdir=/usr/lib \
        --disable-multilib \
        --disable-bootstrap \
        --enable-languages=c,c++ \
    && make -j$(nproc) all-target-libgcc all-target-libstdc++-v3 \
    && mkdir -p /base/usr/lib && ln -s lib /base/usr/lib64 \
    && make install-target-libgcc DESTDIR=/base \
    && make install-target-libstdc++-v3 DESTDIR=/base

WORKDIR /build/zlib
RUN curl --silent --show-error --location --output zlib.tar.gz \
    "${ZLIB_SOURCE}" \
    && tar xf zlib.tar.gz --strip-components=1 \
    && ./configure --prefix=/usr \
    && make -s -j$(nproc) \
    && make install DESTDIR=/base

WORKDIR /build/openssl
RUN curl --silent --show-error --location --output openssl.tar.gz \
    "${OPENSSL_SOURCE}" \
    && tar xf openssl.tar.gz --strip-components=1 \
    && ./Configure linux-x86_64 --prefix=/usr --libdir=/usr/lib no-tests no-docs \
        --with-zlib-include=/base/usr/include --with-zlib-lib=/base/usr/lib \
    && make -s -j$(nproc) \
    && make install DESTDIR=/base

WORKDIR /build/icu
RUN curl --silent --show-error --location --output icu.tar.gz \
    "${ICU_SOURCE}" \
    && tar xf icu.tar.gz --strip-components=1 \
    && cd source \
    && ./configure \
         --prefix=/usr \
         --disable-tests \
         --disable-samples \
    && make -s -j$(nproc) \
    && make install DESTDIR=/base

WORKDIR /build/ncurses
RUN curl --silent --show-error --location --output ncurses.tar.gz \
    "${NCURSES_SOURCE}" \
    && tar xf ncurses.tar.gz --strip-components=1 \
    && ./configure --prefix=/usr --with-shared --without-debug \
        --without-ada --enable-widec --without-cxx \
    && make -s -j$(nproc) \
    && make install DESTDIR=/base

WORKDIR /build/readline
RUN curl --silent --show-error --location --output readline.tar.gz \
    "${READLINE_SOURCE}" \
    && tar xf readline.tar.gz --strip-components=1 \
    && CPPFLAGS="-I/base/usr/include" LDFLAGS="-L/base/usr/lib" \
        ./configure --prefix=/usr --with-curses --enable-multibyte \
    && make -s -j$(nproc) \
    && make install DESTDIR=/base

WORKDIR /build/postgres
RUN curl --silent --show-error --location --output postgresql.tar.gz \
    "${POSTGRES_SOURCE}" \
    && tar xf postgresql.tar.gz --strip-components=1 \
    && CPPFLAGS="-I/base/usr/include" LDFLAGS="-L/base/usr/lib" \
        ./configure --prefix=/usr --disable-rpath --with-openssl \
        --enable-thread-safety --with-uuid=e2fs \
    && make -s -j$(nproc) \
    && make install DESTDIR=/base

# Build contrib extensions (including system_stats)
WORKDIR /build/postgres/contrib
RUN make -s -j$(nproc) \
    && make install DESTDIR=/base

# inidtb requires an 'sh' to call postgres
WORKDIR /build/dash
RUN curl --silent --show-error --location --output dash.tar.gz \
    "${DASH_SOURCE}" \
    && tar xf dash.tar.gz --strip-components=1 \
    && ./configure \
    && make -s -j$(nproc) \
    && cp src/dash /base/usr/bin/sh  

WORKDIR /build/entrypoint
COPY entrypoint.c ./entrypoint.c
RUN gcc -O2 -o /base/usr/bin/entrypoint entrypoint.c

RUN rm -fr /base/usr/lib/{pkgconfig,cmake} /base/usr/share/{doc,info}

FROM ghcr.io/simons-public/distroless/base

ARG POSTGRES_VERSION
ARG GCC_VERSION
ARG ZLIB_VERSION
ARG OPENSSL_VERSION
ARG ICU_VERSION
ARG READLINE_VERSION
ARG NCURSES_VERSION
ARG DASH_VERSION

COPY --from=builder /base/usr/lib/ /usr/lib/
COPY --from=builder /base/usr/share/ /usr/share/
COPY --from=builder /base/usr/bin/ /usr/bin/
COPY ./passwd /etc/passwd
COPY ./shadow /etc/shadow

WORKDIR /var/lib/postgresql/data
ENV PSQL_PAGER=""
ENV PGDATA=/var/lib/postgresql/data
ENV PWD=/var/lib/postgresql/data

ENTRYPOINT ["entrypoint", "-h", "0.0.0.0"]

LABEL org.opencontainers.image.title="distroless posgtres"
LABEL org.opencontainers.image.description="distroless posgtres"
LABEL org.opencontainers.image.version="${POSTGRES_VERSION}"
LABEL org.opencontainers.image.volumes.data="/var/lib/postgresql/data"
LABEL org.opencontainers.image.volumes.init="/initdb"
LABEL org.opencontainers.image.source="https://github.com/simons-containers/distroless-postgres"
LABEL org.opencontainers.image.base.libs="gcc@${GCC_VERSION},zlib@${ZLIB_VERSION},openssl@${OPENSSL_VERSION},icu@${ICU_VERSION},readline@${READLINE_VERSION},ncurses@${NCURSES_VERSION},dash@${DASH_VERSION}"