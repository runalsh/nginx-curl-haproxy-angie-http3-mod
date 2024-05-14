
FROM alpine as builder

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apk add --no-cache --virtual .build-deps build-base wget ca-certificates gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers pcre-dev wget zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor cmake samurai libunwind-dev linux-headers perl-dev libstdc++  libssl3 libcrypto3 openssl openssl-dev git luajit-dev libxslt-dev

COPY --from=golang:alpine /usr/local/go/ /usr/local/go/
ENV PATH="/usr/local/go/bin:${PATH}"

RUN mkdir -p /tmp/build/angie && \
    cd /tmp/build/angie && \
    wget -O angie-${ANGIE_VERSION}.tar.gz https://download.angie.software/files/angie-${ANGIE_VERSION}.tar.gz && \
    tar -zxf angie-${ANGIE_VERSION}.tar.gz

RUN mkdir -p /tmp/build/module && \
    cd /tmp/build/module && \
    wget -O ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    tar -zxf ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    cd ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}

RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    patch -p1 < /tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}/patch/proxy_connect_rewrite_102101.patch

# RUN cd /tmp/build/module && \
#     git clone --depth=1 https://github.com/vozlt/nginx-module-vts nginx-module-vts

# RUN cd /tmp/build/module && \    
#     git clone --depth=1 https://github.com/vozlt/nginx-module-sts nginx-module-sts && \
#     git clone --depth=1 https://github.com/vozlt/nginx-module-stream-sts nginx-module-stream-sts

# https://tengine.taobao.org/document/ngx_debug_pool.html
# RUN cd /tmp/build/module && \
#     git clone --depth=1  https://github.com/alibaba/tengine tengine

# https://habr.com/ru/articles/680992/
# https://github.com/openresty/lua-nginx-module#installation
# https://github.com/chobits/ngx_http_proxy_connect_module/blob/master/t/http_proxy_connect.t#L113
# https://github.com/Container-Projects/CentOS-Dockerfiles/blob/master/lua-nginx/install.sh
# https://github.com/search?q=ngx_http_proxy_connect_module+lua_package_path&type=code
# https://github.com/AHH0623/tengine-ingress/blob/999ee15cda5c50718e5791bdd91366895432d50b/images/tengine/rootfs/build.sh#L112
# angie-module-lua
# RUN cd /tmp/build/module && \
#     git clone --depth=1  https://github.com/openresty/lua-nginx-module && \
#     git clone --depth=1  https://github.com/vision5/ngx_devel_kit && \
#     git clone --depth=1  https://github.com/openresty/luajit2 && cd luajit2 && make && make install && cd /tmp/build/module && \
#     git clone --depth=1  https://github.com/openresty/lua-resty-core && cd lua-resty-core && mkdir -p /usr/local/lib/lua/resty/core && make install && cd /tmp/build/module && \
#     git clone --depth=1  https://github.com/openresty/lua-resty-lrucache && cd lua-resty-lrucache && make install && cd /tmp/build/module && \
#     git clone --depth=1  https://github.com/openresty/lua-upstream-nginx-module && cd lua-upstream-nginx-module && make install && cd /tmp/build/module && \
#     git clone --depth=1  https://github.com/openresty/stream-lua-nginx-module && cd stream-lua-nginx-module && make install && cd /tmp/build/module && \
#     export LUAJIT_LIB=/usr/local/lib/ && export LUAJIT_INC=/usr/local/include/luajit-2.1/

RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    ./configure \
    --prefix=/etc/angie --conf-path=/etc/angie/angie.conf \
    --error-log-path=/var/log/angie/error.log --http-log-path=/var/log/angie/access.log --lock-path=/run/angie.lock \
    --modules-path=/usr/lib/angie/modules --pid-path=/run/angie.pid --sbin-path=/usr/sbin/angie \
    --http-acme-client-path=/var/lib/angie/acme --http-client-body-temp-path=/var/cache/angie/client_temp  \
    --http-fastcgi-temp-path=/var/cache/angie/fastcgi_temp --http-proxy-temp-path=/var/cache/angie/proxy_temp \
    --http-scgi-temp-path=/var/cache/angie/scgi_temp --http-uwsgi-temp-path=/var/cache/angie/uwsgi_temp \
    --user=angie --group=angie \
    --with-file-aio --with-http_acme_module --with-http_addition_module --with-http_auth_request_module \
    --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module \
    --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module \
    --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module \
    --with-stream --with-stream_mqtt_preread_module --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-threads \
    --with-ld-opt='-Wl,--as-needed,-O1,--sort-common -Wl,-z,pack-relative-relocs' \
    --with-compat --add-module=/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}
    # --add-module=/tmp/build/module/lua-nginx-module --add-module=/tmp/build/module/ngx_devel_kit --add-module=/tmp/build/module/stream-lua-nginx-module --add-module=/tmp/build/module/lua-upstream-nginx-module \\  -Wl,-rpath,/usr/local/lib/
    # --add-module=/tmp/build/module/nginx-module-vts \
    # --add-module=/tmp/build/module/nginx-module-sts --add-module=/tmp/build/module/nginx-module-stream-sts \
    # --add-module=/tmp/build/module/tengine/modules/ngx_debug_pool
    
RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    make -j$proc && \
    make install DESTDIR=/tmp/build/angie/angie-release-build && \
    ls -la /tmp/build/angie/angie-release-build

RUN apk del .build-deps

FROM alpine

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

COPY --from=builder /tmp/build/angie/angie-release-build/usr /usr
COPY --from=builder /tmp/build/angie/angie-release-build/var /var
COPY --from=builder /tmp/build/angie/angie-release-build/etc /etc

RUN apk add --no-cache ca-certificates curl \
    && curl -o /etc/apk/keys/angie-signing.rsa https://angie.software/keys/angie-signing.rsa \
    && echo "https://download.angie.software/angie/alpine/v$(egrep -o \
        '[0-9]+\.[0-9]+' /etc/alpine-release)/main" >> /etc/apk/repositories \
    && apk add --no-cache angie-console-light \
    && rm /etc/apk/keys/angie-signing.rsa \
    # && ln -sf /dev/stdout /var/log/angie/access.log \
    && ln -sf /dev/stderr /var/log/angie/error.log \
    && mkdir -p /var/cache/angie

RUN angie -V

CMD ["angie", "-g", "daemon off;"]