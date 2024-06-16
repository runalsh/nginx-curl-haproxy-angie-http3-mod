
# FROM alpine:3.20 as builder
FROM runalsh/builder:alpine as builder

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6
ENV QUICTLS_VERSION 3.1.5

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE
ARG QUICTLS_VERSION

# RUN apk add --no-cache --virtual .build-deps build-base wget ca-certificates gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers pcre-dev wget curl zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor cmake samurai libunwind-dev linux-headers perl-dev libstdc++  libssl3 libcrypto3 openssl openssl-dev git luajit-dev libxslt-dev

# COPY --from=golang:alpine /usr/local/go/ /usr/local/go/
# ENV PATH="/usr/local/go/bin:${PATH}"

RUN mkdir -p /tmp/build/angie && \
    cd /tmp/build/angie && \
    wget -O angie-${ANGIE_VERSION}.tar.gz https://download.angie.software/files/angie-${ANGIE_VERSION}.tar.gz && \
    tar -zxf angie-${ANGIE_VERSION}.tar.gz && \
    sed -i -e '1i pid /tmp/angie.pid;\n' angie-${ANGIE_VERSION}/conf/angie.conf && \
    sed -i -e 's/listen       80;/listen 8080;/g' angie-${ANGIE_VERSION}/conf/angie.conf 

RUN mkdir -p /tmp/build/module && \
    cd /tmp/build/module && \
    wget -O ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    tar -zxf ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    patch -p1 < /tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}/patch/proxy_connect_rewrite_102101.patch

RUN mkdir -p /tmp/build/module && \
    cd /tmp/build/module && \
    git clone --recursive --depth 1 -b openssl-${QUICTLS_VERSION}+quic https://github.com/quictls/openssl

RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    ./configure \
    --prefix=/etc/angie \ 
    --conf-path=/etc/angie/angie.conf \
    --error-log-path=/var/log/angie/error.log \ 
    --http-log-path=/var/log/angie/access.log \ 
    --lock-path=/run/angie.lock \
    --modules-path=/usr/lib/angie/modules \ 
    --pid-path=/tmp/angie.pid \ 
    --sbin-path=/usr/sbin/angie \
    --http-acme-client-path=/var/lib/angie/acme \ 
    --http-client-body-temp-path=/var/cache/angie/client_temp  \
    --http-fastcgi-temp-path=/var/cache/angie/fastcgi_temp \ 
    --http-proxy-temp-path=/var/cache/angie/proxy_temp \
    --http-scgi-temp-path=/var/cache/angie/scgi_temp \ 
    --http-uwsgi-temp-path=/var/cache/angie/uwsgi_temp \
    --user=angie \ 
    --group=angie \
    --with-compat \
    --with-file-aio \ 
    --with-http_acme_module \ 
    --with-http_addition_module \ 
    --with-http_auth_request_module \
    --with-http_dav_module \ 
    --with-http_gunzip_module \ 
    --with-http_gzip_static_module \ 
    --with-http_random_index_module \ 
    --with-http_realip_module \ 
    --with-http_secure_link_module \ 
    --with-http_slice_module \ 
    --with-http_ssl_module \
    --with-http_stub_status_module \ 
    --with-http_sub_module \ 
    --with-http_v2_module \ 
    --with-http_v3_module \ 
    --with-stream \ 
    --with-stream_mqtt_preread_module \ 
    --with-stream_realip_module \ 
    --with-stream_ssl_module \ 
    --with-stream_ssl_preread_module \ 
    --with-threads \
    --with-openssl="/tmp/build/module/openssl" \
    --with-openssl-opt=enable-ktls \
    --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
    --with-ld-opt='-Wl,--as-needed,-O1,--sort-common -Wl,-z,pack-relative-relocs' \
    --with-cc-opt="-O2 -g -m64 -march=westmere -falign-functions=32 -flto -funsafe-math-optimizations -fstack-protector-strong --param=ssp-buffer-size=4 -Wimplicit-fallthrough=0 -Wno-error=strict-aliasing -Wformat -Wno-error=pointer-sign -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error=unused-result -Wno-unused-result -fcode-hoisting -Werror=format-security -Wno-deprecated-declarations -Wp,-D_FORTIFY_SOURCE=2 -DTCP_FASTOPEN=23 -fPIC" \
    --add-module="/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}" 
   
    # --add-module=/tmp/build/module/lua-nginx-module --add-module=/tmp/build/module/ngx_devel_kit --add-module=/tmp/build/module/stream-lua-nginx-module --add-module=/tmp/build/module/lua-upstream-nginx-module \\  -Wl,-rpath,/usr/local/lib/
    # --add-module=/tmp/build/module/nginx-module-vts \
    # --add-module=/tmp/build/module/nginx-module-sts --add-module=/tmp/build/module/nginx-module-stream-sts \
    # --add-module=/tmp/build/module/tengine/modules/ngx_debug_pool
    # --with-mail \ 
    # --with-mail_ssl_module \
    # --with-debug \
    # --with-http_mp4_module \
    # --with-http_flv_module \ 
    # --with-pcre-jit \
    
RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    make -j$proc && \
    make install DESTDIR=/tmp/build/angie/angie-release-build && \
    ls -la /tmp/build/angie/angie-release-build && \
    curl -o /etc/apk/keys/angie-signing.rsa https://angie.software/keys/angie-signing.rsa && \
    echo "https://download.angie.software/angie/alpine/v$(egrep -o '[0-9]+\.[0-9]+' /etc/alpine-release)/main" >> /etc/apk/repositories && \
    apk add --no-cache angie-console-light

# RUN apk del .build-deps

FROM alpine:3.20

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6
ENV QUICTLS_VERSION 3.1.5

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE
ARG QUICTLS_VERSION

COPY --from=builder /tmp/build/angie/angie-release-build/usr /usr
COPY --from=builder /tmp/build/angie/angie-release-build/var /var
COPY --from=builder /tmp/build/angie/angie-release-build/etc /etc
COPY --from=builder /usr/share/angie-console-light /usr/share/angie-console-light

RUN addgroup -S angie && adduser -S angie -s /sbin/nologin -G angie --uid 101 --no-create-home
RUN apk add --no-cache ca-certificates pcre && \
    # && ln -sf /dev/stdout /var/log/angie/access.log \
    ln -sf /dev/stderr /var/log/angie/error.log

RUN mkdir -p /var/cache/angie && chown -R angie:angie /var/cache/angie && chmod -R g+w /var/cache/angie && \
    chown -R angie:angie /etc/angie && chmod -R g+w /etc/angie && \
    mkdir -p /var/log/angie && chown -R angie:angie /var/log/angie && chmod -R g+w /var/log/angie && \
    mkdir -p /usr/lib/angie && chown -R angie:angie /usr/lib/angie && chmod -R g+w /usr/lib/angie

EXPOSE 8080/tcp

STOPSIGNAL SIGQUIT

USER angie

RUN angie -V && angie -t

CMD ["angie", "-g", "daemon off;"]