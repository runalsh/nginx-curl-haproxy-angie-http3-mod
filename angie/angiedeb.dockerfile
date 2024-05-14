FROM buildpack-deps:latest as builder

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install locales wget ca-certificates openssl gnupg2 apt-transport-https unzip make libpcre3-dev zlib1g-dev build-essential devscripts debhelper quilt lsb-release libssl-dev lintian uuid-dev
    
RUN apt-get --no-install-recommends --no-install-suggests -y install libjansson-dev libldap-dev libhiredis-dev libgd-dev libjwt-dev liblua5.3-dev liblmdb++-dev libyajl-dev expect libedit-dev cmake libmsgpack-dev libperl-dev libavcodec-dev libswscale-dev && \   
rm -rf /var/lib/apt/lists/*

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

#nginx defaul
# RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
#     ./configure \
#     --prefix=/etc/angie --sbin-path=/usr/sbin/angie --modules-path=/usr/lib/angie/modules \
# 	--conf-path=/etc/angie/angie.conf --error-log-path=/var/log/angie/error.log --http-log-path=/var/log/angie/access.log \
# 	--pid-path=/var/run/angie.pid --lock-path=/var/run/angie.lock \
# 	--http-client-body-temp-path=/var/cache/angie/client_temp --http-proxy-temp-path=/var/cache/angie/proxy_temp --http-fastcgi-temp-path=/var/cache/angie/fastcgi_temp --http-uwsgi-temp-path=/var/cache/angie/uwsgi_temp --http-scgi-temp-path=/var/cache/angie/scgi_temp \
# 	--user=angie --group=angie \
# 	--with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module \
#     --with-http_v2_module --with-http_v3_module \
# 	--add-module=/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}

# from angie -V
# --prefix=/etc/angie --conf-path=/etc/angie/angie.conf --error-log-path=/var/log/angie/error.log --http-log-path=/var/log/angie/access.log --lock-path=/run/angie.lock --modules-path=/usr/lib/angie/modules --pid-path=/run/angie.pid --sbin-path=/usr/sbin/angie --http-acme-client-path=/var/lib/angie/acme --http-client-body-temp-path=/var/cache/angie/client_temp --http-fastcgi-temp-path=/var/cache/angie/fastcgi_temp --http-proxy-temp-path=/var/cache/angie/proxy_temp --http-scgi-temp-path=/var/cache/angie/scgi_temp --http-uwsgi-temp-path=/var/cache/angie/uwsgi_temp --user=angie --group=angie --with-file-aio --with-http_acme_module --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module --with-stream --with-stream_mqtt_preread_module --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-threads --with-debug --feature-cache=../angie-feature-cache --with-ld-opt='-Wl,-z,relro -Wl,-z,now'

# RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
#     make -j$proc && \
#     make install

# RUN mkdir /var/lock/angie && \
#     mkdir -p /var/cache/angie && \
#     adduser --system --no-create-home --shell /bin/false --group --disabled-login angie    

RUN osversion=$(lsb_release -cs) && \
    cd /tmp/build/angie && \
    wget https://download.angie.software/angie/debian/pool/main/a/angie/angie_${ANGIE_VERSION}-1~$osversion.debian.tar.xz && \
    tar -xJf angie_${ANGIE_VERSION}-1~$osversion.debian.tar.xz -C ./angie-${ANGIE_VERSION}

RUN sed -i "s#--with-threads#--with-threads --add-module=/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}#g" /tmp/build/angie/angie-${ANGIE_VERSION}/debian/rules

RUN cd /tmp/build/angie/angie-${ANGIE_VERSION} && \
    ls -la && \
    echo "configure-accelerator.patch" > debian/patches/series && \
    # make clean && \
    dpkg-buildpackage -uc -us -b && \
    ls -la /tmp/build/angie/  && \
    osversion=$(lsb_release -cs) && \
    mv /tmp/build/angie/angie_${ANGIE_VERSION}-1~"$osversion"_amd64.deb /tmp/build/angie/angie_${ANGIE_VERSION}_amd64.deb && \
    dpkg -i /tmp/build/angie/angie_${ANGIE_VERSION}_amd64.deb

RUN /tmp/build/angie/angie-${ANGIE_VERSION}/debian/build-angie/objs/angie -V

# EXPOSE 80
# EXPOSE 443

# # COPY angie/angie.conf /etc/angie/angie.conf

# RUN mkdir -p /var/log/angie && \
#     touch /var/log/angie/{error.log,access.log} && \
#     ln -sf /dev/stdout /var/log/angie/error.log && \
#     ln -sf /dev/stdout /var/log/angie/access.log

FROM debian:12-slim

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests -y install libssl-dev && \
    apt clean && apt autoclean && apt autoremove && \
    rm -rf /var/lib/apt/*

COPY --from=builder /tmp/build/angie/angie_${ANGIE_VERSION}_amd64.deb /tmp/angie_${ANGIE_VERSION}_amd64.deb
RUN dpkg -i /tmp/angie_${ANGIE_VERSION}_amd64.deb
# RUN rm -rf /tmp/angie_${ANGIE_VERSION}_amd64.deb

RUN angie -V; angie -t

CMD ["angie", "-g", "daemon off;"]
# CMD ["sleep", "99999999"]








