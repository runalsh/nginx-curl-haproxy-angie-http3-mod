
FROM debian:12-slim as builder

ENV ANGIE_VERSION 1.5.2
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apt update && apt install -y --no-install-recommends ca-certificates curl wget lsb-release && \
    curl -o /etc/apt/trusted.gpg.d/angie-signing.gpg https://angie.software/keys/angie-signing.gpg

RUN cat <<EOF >> /etc/apt/sources.list
deb http://mirror.yandex.ru/debian/ `lsb_release -cs` main non-free-firmware
deb-src http://mirror.yandex.ru/debian/ `lsb_release -cs` main non-free-firmware
deb http://security.debian.org/debian-security `lsb_release -cs`-security main non-free-firmware
deb-src http://security.debian.org/debian-security `lsb_release -cs`-security main non-free-firmware
deb http://mirror.yandex.ru/debian/ `lsb_release -cs`-updates main non-free-firmware
deb-src http://mirror.yandex.ru/debian/ `lsb_release -cs`-updates main non-free-firmware
EOF

RUN cat <<EOF >> /etc/apt/sources.list.d/angie.list
    deb https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID $VERSION_CODENAME") main
    deb-src https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID $VERSION_CODENAME") main
EOF
# RUN apt update  && apt install -y devscripts dh-make
# RUN apt install --no-install-recommends --no-install-suggests -y libjansson-dev libldap-dev libkrb5-dev libbrotli-dev libmaxminddb-dev libhiredis-dev libgd-dev libjwt-dev liblua5.3-dev liblmdb++-dev libyajl-dev cmake libcurl4-openssl-dev libmsgpack-dev libperl-dev libpq-dev libavcodec-dev libswscale-dev libxslt1-dev libzstd-dev
RUN apt update
RUN apt install -y --no-install-recommends locales openssl gnupg2 apt-transport-https unzip make libpcre2-dev zlib1g-dev build-essential devscripts debhelper quilt lsb-release libssl-dev lintian uuid-dev dpkg-dev

RUN mkdir -p /tmp/build/module && \
    cd /tmp/build/module && \
    wget -O ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    tar -zxf ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    cd ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}
  
RUN mkdir -p /tmp/build/angie && cd /tmp/build/angie && \
    apt source angie=$(apt-cache policy angie | grep ${ANGIE_VERSION}- | awk '{print $1}' | grep ${ANGIE_VERSION} |sort -V | tail -n 1) && \
    cd angie-${ANGIE_VERSION} && \
    patch -p1 < /tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}/patch/proxy_connect_rewrite_102101.patch

COPY debrules /tmp/build/angie/angie-${ANGIE_VERSION}/debian/rules
COPY debcontrol /tmp/build/angie/angie-${ANGIE_VERSION}/debian/control

RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    sed -i "s#--with-threads#--with-threads --add-module=/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}#g" debian/rules && \
    # rm -rf debian/angie-module* && \
    dpkg-buildpackage -uc -us -b
    
RUN mkdir -p /tmp/angie && \
    # find /tmp/build/angie/ -type f -name angie_*_amd64.deb -print0 | xargs -0 -I'{}' mv '{}' /tmp/angie/angie_${ANGIE_VERSION}_amd64.deb && \
    wget -O /tmp/build/angie/angie-console-light.deb https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID")/pool/main/a/angie-console-light/$(curl https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID")/pool/main/a/angie-console-light/ | grep -oE "angie-console-light_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+~`lsb_release -cs`_all\.deb" | sort -V | tail -n 1) && \
    rm -rf /tmp/build/angie/*dbgsym* && \
    cp /tmp/build/angie/*.deb /tmp/angie && \
    rm -rf /tmp/build && \
    ls -la /tmp/angie

FROM debian:12-slim

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install libssl-dev && \
    apt clean && apt autoclean && apt autoremove -y && \
    rm -rf /var/lib/apt/* && \
    mkdir -p /tmp/angie

COPY --from=builder /tmp/angie/*.deb /tmp/angie

RUN dpkg -i /tmp/angie/*.deb && \
    # ln -sf /dev/stdout /var/log/angie/access.log \
    ln -sf /dev/stderr /var/log/angie/error.log
    # rm -rf /tmp/angie

RUN angie -V; angie -t

CMD ["angie", "-g", "daemon off;"]
# CMD ["sleep", "99999999"]

