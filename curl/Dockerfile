FROM buildpack-deps:latest as builder

ENV CURL_VERSION 8.7.1
ENV QUICHE_VERSION 0.20.1
RUN export LANGUAGE=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && export LANG=en_US.UTF-8 && export LC_CTYPE=en_US.UTF-8

ARG CURL_VERSION
ARG QUICHE_VERSION

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install locales wget ca-certificates curl openssl gnupg2 apt-transport-https unzip make libpcre3-dev zlib1g-dev build-essential devscripts debhelper quilt lsb-release libssl-dev lintian uuid-dev && \
    apt-get --no-install-recommends --no-install-suggests -y install git libnghttp2-dev libtool autoconf automake libbrotli-dev pkg-config cmake  && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root
ENV HOME /root

RUN wget https://sh.rustup.rs -O - | sh -s -- -y

ENV PATH "${PATH}:$HOME/.cargo/bin"
RUN cargo --version; rustc --version

RUN mkdir -p /tmp/build/curl && \
    cd /tmp/build/curl && \
    git clone -b ${QUICHE_VERSION} --depth 1 --single-branch https://github.com/cloudflare/quiche.git quiche-${QUICHE_VERSION} && \
    cd quiche-${QUICHE_VERSION} && \
    git submodule init && \
    git submodule update && \
    cargo build --package quiche --release --features ffi,pkg-config-meta,qlog

RUN cd /tmp/build/curl/quiche-${QUICHE_VERSION} && \
    mkdir -p quiche/deps/boringssl/src/lib && \
    ln -vnf $(find target/release -name libcrypto.a -o -name libssl.a) quiche/deps/boringssl/src/lib/

RUN cd /tmp/build/curl && \
    CURL_VERSION_MOD=$(echo "$CURL_VERSION" | sed "s/\./\_/g") && echo $CURL_VERSION_MOD && \
    wget -O curl-${CURL_VERSION}.tar.gz https://github.com/curl/curl/releases/download/curl-$CURL_VERSION_MOD/curl-${CURL_VERSION}.tar.gz && \
    tar -zxf curl-${CURL_VERSION}.tar.gz && \
    cd curl-${CURL_VERSION} && \
    autoreconf -fi && \
    ./configure LDFLAGS="-Wl,-rpath,/tmp/build/curl/quiche-${QUICHE_VERSION}/target/release" \
    --with-brotli \
    --with-nghttp2 \
    --with-openssl=/tmp/build/curl/quiche-${QUICHE_VERSION}/quiche/deps/boringssl/src \
    --with-quiche=/tmp/build/curl/quiche-${QUICHE_VERSION}/target/release \
    --with-zlib && \
    make -j$proc && \
    make DESTDIR="/tmp/build/curl/curl-${CURL_VERSION}-build/" install

    # make -j$proc
    # && \
    # make install
#   wget http://ftp.de.debian.org/debian/pool/main/c/curl/curl_8.6.0-4.debian.tar.xz && \
#   tar -xJf curl_8.6.0-4.debian.tar.xz -C ./curl-${CURL_VERSION} && \

RUN /tmp/build/curl/curl-${CURL_VERSION}-build/usr/local/bin/curl --version


FROM alpine:latest
ARG CURL_VERSION
ARG QUICHE_VERSION

ENV CURL_VERSION   $CURL_VERSION
ENV QUICHE_VERSION $QUICHE_VERSION

COPY --from=builder /tmp/build/curl/curl-${CURL_VERSION}-build/usr/local/bin/curl /usr/local/bin/curl
COPY --from=builder /tmp/build/curl/curl-${CURL_VERSION}-build/usr/local/lib/libcurl.so.4 /usr/local/lib/libcurl.so.4
COPY --from=builder /usr/lib/x86_64_linux_gnu/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
COPY --from=builder /usr/lib/x86_64_linux_gnu/libnghttp2.so.14 /usr/lib/libnghttp2.so.14
COPY --from=builder /usr/lib/x86_64_linux_gnu/libbrotlidec.so.1 /usr/lib/libbrotlidec.so.1
COPY --from=builder /lib/x86_64_linux_gnu/libz.so.1 /lib/libz.so.1
COPY --from=builder /usr/lib/x86_64_linux_gnu/libbrotlicommon.so.1 /usr/lib/libbrotlicommon.so.1

USER nobody
RUN env | sort; which curl; curl --version


















