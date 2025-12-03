
FROM alpine:3.23 AS base

ENV CURL_VERSION 8.7.1
ENV QUICHE_VERSION 0.20.1
ARG CURL_VERSION
ARG QUICHE_VERSION

RUN mkdir -p /tmp/build/curl/cargo
ENV HOME /tmp/build/curl/cargo

RUN apk add --no-cache \
  autoconf \
  automake \
  brotli-dev \
  build-base \
  cmake \
  git \
  libtool \
  nghttp2-dev \
  pkgconfig \
  wget \
  zlib-dev \
  libpsl-dev \
  libidn2-dev

RUN wget https://sh.rustup.rs -O - | sh -s -- -y

ENV PATH "${PATH}:$HOME/.cargo/bin"
RUN cargo --version; rustc --version

RUN cd /tmp/build/curl && \
  git clone -b ${QUICHE_VERSION} --depth 1 --single-branch https://github.com/cloudflare/quiche.git quiche-${QUICHE_VERSION} && \
  cd quiche-${QUICHE_VERSION} && \
  git submodule init && \
  git submodule update && \
  cargo build --package quiche --release --features ffi,pkg-config-meta,qlog && \
  cp -r /tmp/build/curl/quiche-${QUICHE_VERSION}/target/release/ /tmp/build/curl/quiche-build/

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
  make DESTDIR="/tmp/build/curl/curl-build/" install && \
  make install && \
  ls -la /tmp/build/curl/curl-build

FROM alpine:3.23

ENV CURL_VERSION 8.7.1
ENV QUICHE_VERSION 0.20.1
ARG CURL_VERSION
ARG QUICHE_VERSION

COPY --from=base /tmp/build/curl/curl-build/usr /usr
# COPY --from=base /tmp/build/curl/quiche-build/libquiche.so /usr/lib/libquiche.so
COPY --from=base /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
COPY --from=base /usr/lib/libnghttp2.so.14 /usr/lib/libnghttp2.so.14
COPY --from=base /usr/lib/libbrotlidec.so.1 /usr/lib/libbrotlidec.so.1
COPY --from=base /lib/libz.so.1 /lib/libz.so.1
COPY --from=base /usr/lib/libbrotlicommon.so.1 /usr/lib/libbrotlicommon.so.1
COPY --from=base /usr/lib/libidn2.so.0 /usr/lib/libidn2.so.0
COPY --from=base /usr/lib/libpsl.so.5 /usr/lib/libpsl.so.5
COPY --from=base /usr/lib/libunistring.so.5 /usr/lib/libunistring.so.5

USER nobody
RUN env | sort; which curl; curl --version
