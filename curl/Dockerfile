FROM buildpack-deps:latest

ARG CURL_VERSION 8.7.1
ARG QUICHE_VERSION 0.20.1

ARG CURL_VERSION
ARG QUICHE_VERSION

RUN CURL_VERSION_MOD=$(echo "$CURL_VERSION" | sed "s/\./\_/g") && export LANGUAGE=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && export LANG=en_US.UTF-8 && export LC_CTYPE=en_US.UTF-8

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install wget ca-certificates curl openssl gnupg2 apt-transport-https unzip make libpcre3-dev zlib1g-dev build-essential devscripts debhelper quilt lsb-release libssl-dev lintian uuid-dev && \
    apt-get --no-install-recommends --no-install-suggests -y install git libnghttp2-dev libtool autoconf automake libbrotli-dev pkg-config cmake  && \
    rm -rf /var/lib/apt/lists/*

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

RUN mkdir /tmp/build/curl/quiche-{QUICHE_VERSION}/quiche/deps/boringssl/src/lib/ && \
  ln -vnf $(find /tmp/build/curl/quiche-{QUICHE_VERSION}/target/release/build/ -name libcrypto.a -o -name libssl.a) /tmp/build/curl/quiche-{QUICHE_VERSION}/quiche/deps/boringssl/src/lib/

RUN cd /tmp/build/curl && \
  wget -O curl-${CURL_VERSION}.tar.gz https://github.com/curl/curl/releases/download/curl-${CURL_VERSION_MOD}/curl-${CURL_VERSION}.tar.gz && \
  tar -zxf curl-${CURL_VERSION}.tar.gz && \
#   wget http://ftp.de.debian.org/debian/pool/main/c/curl/curl_8.6.0-4.debian.tar.xz && \
#   tar -xJf curl_8.6.0-4.debian.tar.xz -C ./curl-${CURL_VERSION} && \
  cd curl-${CURL_VERSION} && \
  autoreconf -fi && \
  ./configure LDFLAGS="-Wl,-rpath,/tmp/build/curl/quiche-{QUICHE_VERSION}/target/release" \
    --with-brotli \
    --with-nghttp2 \
    # --with-libssh2 \
    --with-openssl=/tmp/build/curl/quiche-{QUICHE_VERSION}/quiche/deps/boringssl/src \
    --with-quiche=/tmp/build/curl/quiche-{QUICHE_VERSION}/target/release \
    --with-zlib && \
    make 
    # && \
    # make install
    # make DESTDIR="/tmp/build/curl/curl-${CURL_VERSION}-build/" install

























