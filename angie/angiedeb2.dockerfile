
FROM debian:12-slim as builder

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apt update && apt install -y --no-install-recommends ca-certificates curl wget lsb-release && \
    curl -o /etc/apt/trusted.gpg.d/angie-signing.gpg https://angie.software/keys/angie-signing.gpg  && \
    echo "deb https://download.angie.software/angie/debian/ `lsb_release -cs` main" | tee /etc/apt/sources.list.d/angie.list > /dev/null && \
    echo "deb-src https://download.angie.software/angie/debian/ `lsb_release -cs` main" | tee /etc/apt/sources.list.d/angie.list >/dev/null

RUN cat <<EOF > /etc/apt/sources.list
deb http://mirror.yandex.ru/debian/ bookworm main non-free-firmware
deb-src http://mirror.yandex.ru/debian/ bookworm main non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware
# bookworm-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
deb http://mirror.yandex.ru/debian/ bookworm-updates main non-free-firmware
deb-src http://mirror.yandex.ru/debian/ bookworm-updates main non-free-firmware
EOF
# RUN apt update  && apt install -y devscripts dh-make
# RUN  apt install -y expect libedit-dev libpcre2-dev libssl-dev mmv zlib1g-dev
# RUN apt install --no-install-recommends --no-install-suggests -y libjansson-dev libldap-dev libkrb5-dev libbrotli-dev libmaxminddb-dev libhiredis-dev libgd-dev libjwt-dev liblua5.3-dev liblmdb++-dev libyajl-dev cmake libcurl4-openssl-dev libmsgpack-dev libperl-dev libpq-dev libavcodec-dev libswscale-dev libxslt1-dev libzstd-dev
RUN apt update && apt install -y --no-install-recommends locales openssl gnupg2 apt-transport-https unzip make libpcre2-dev zlib1g-dev build-essential devscripts debhelper quilt lsb-release libssl-dev lintian uuid-dev dpkg-dev

RUN mkdir -p /tmp/build/module && \
    cd /tmp/build/module && \
    wget -O ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    tar -zxf ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    cd ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}
  
RUN mkdir -p /tmp/build/angie && cd /tmp/build/angie && \
    apt source angie && \
    # apt source angie=$(apt-cache policy angie | grep ${ANGIE_VERSION}- | awk '{print $1}' | grep ${ANGIE_VERSION} |sort -V | tail -n 1) && \
    cd angie-${ANGIE_VERSION} && \
    patch -p1 < /tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}/patch/proxy_connect_rewrite_102101.patch

COPY angie/debrules /tmp/build/angie/angie-${ANGIE_VERSION}/debian/rules
COPY angie/debcontrol /tmp/build/angie/angie-${ANGIE_VERSION}/debian/control

RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    sed -i "s#--with-threads#--with-threads --add-module=/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}#g" debian/rules && \
    # rm -rf debian/angie-module* && \
    dpkg-buildpackage -uc -us -b 
    
RUN find /tmp/build/angie/ -type f -name angie_*_amd64.deb -print0 | xargs -0 -I'{}' cp '{}' /tmp/angie_${ANGIE_VERSION}_amd64.deb && ls -la /tmp && \
    rm -rf /tmp/build

FROM debian:12-slim

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install libssl-dev && \
    apt clean && apt autoclean && apt autoremove && \
    rm -rf /var/lib/apt/*

COPY --from=builder /tmp/angie_${ANGIE_VERSION}_amd64.deb /tmp/angie_${ANGIE_VERSION}_amd64.deb
RUN dpkg -i /tmp/angie_${ANGIE_VERSION}_amd64.deb && \
    # && ln -sf /dev/stdout /var/log/angie/access.log \
    ln -sf /dev/stderr /var/log/angie/error.log
    # RUN rm -rf /tmp/angie_${ANGIE_VERSION}_amd64.deb

RUN angie -V; angie -t

CMD ["angie", "-g", "daemon off;"]
# CMD ["sleep", "99999999"]

