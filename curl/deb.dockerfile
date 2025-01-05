# FROM buildpack-deps:latest as builder
FROM debian:12-slim as builder

ENV CURL_VERSION 8.7.1
ENV QUICHE_VERSION 0.20.1
RUN export LANGUAGE=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && export LANG=en_US.UTF-8 && export LC_CTYPE=en_US.UTF-8

ARG CURL_VERSION
ARG QUICHE_VERSION

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install locales wget ca-certificates  openssl gnupg2 apt-transport-https unzip make libpcre3-dev zlib1g-dev build-essential devscripts debhelper quilt lsb-release libssl-dev lintian uuid-dev && \
    apt-get --no-install-recommends --no-install-suggests -y install git libnghttp2-dev libtool autoconf automake libbrotli-dev libpsl-dev pkg-config cmake  && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/build/curl/cargo
ENV HOME /tmp/build/curl/cargo

RUN wget https://sh.rustup.rs -O - | sh -s -- -y

ENV PATH "${PATH}:$HOME/.cargo/bin"
RUN cargo --version; rustc --version

RUN mkdir -p /tmp/build/curl && \
    cd /tmp/build/curl && \
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
    make DESTDIR="/tmp/build/curl/curl-build/" install

RUN /tmp/build/curl/curl-build/usr/local/bin/curl --version

RUN apt update && apt-get install dh-make dpkg-dev build-essential fakeroot \
    cd /tmp/build/curl/ \
    mkdir -p curl-deb/DEBIAN \
    echo "Package: curl" > curl-deb/DEBIAN/control && \
    echo "Version: $CURL_VERSION" >> curl-deb/DEBIAN/control && \
    echo "Section: web" >> curl-deb/DEBIAN/control && \
    echo "Architecture: $(dpkg --print-architecture)" >> curl-deb/DEBIAN/control && \
    echo "Depends: libc6, libssl3, zlib1g, libbrotli1, libnghttp2-14, libbrotli-dev, libnghttp2-dev, ca-certificates, libpsl" >> curl-deb/DEBIAN/control && \
    cp -a curl-build/* curl-deb/ \
    chmod -R 755 curl-deb/DEBIAN \
    dpkg-deb --build curl-deb \
    mv curl-deb.deb curl_${CURL_VERSION}_$(dpkg --print-architecture).deb \
    sudo dpkg -i curl_${CURL_VERSION}_$(dpkg --print-architecture).deb \
    curl -version

FROM debian:12-slim

ENV CURL_VERSION 8.7.1
ENV QUICHE_VERSION 0.20.1

ARG CURL_VERSION
ARG QUICHE_VERSION

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y ca-certificates && rm -rf /var/lib/apt/lists/*

#COPY --from=builder /tmp/build/curl/curl-build/usr /usr
#COPY --from=builder /tmp/build/curl/quiche-build/libquiche.so /usr/lib/libquiche.so
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libnghttp2.so.14 /usr/lib/libnghttp2.so.14
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libbrotlidec.so.1 /usr/lib/libbrotlidec.so.1
#COPY --from=builder /lib/x86_64-linux-gnu/libz.so.1 /lib/libz.so.1
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libbrotlicommon.so.1 /usr/lib/libbrotlicommon.so.1
#COPY --from=builder /usr/lib/x86_64-linux-gnu/libpsl.so.5 /usr/lib/libpsl.so.5

COPY --from=builder /tmp/build/curl/curl_${CURL_VERSION}_amd64.deb /tmp/curl_${CURL_VERSION}_amd64.deb
RUN dpkg -i /tmp/curl_${CURL_VERSION}_amd64.deb


RUN ldconfig
RUN env | sort; which curl; curl --version
CMD ["curl"]


