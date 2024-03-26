FROM buildpack-deps:latest

ENV NGINX_VERSION 1.25.4
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

RUN apt-get update && \
    apt-get install -y ca-certificates openssl libssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O nginx-${NGINX_VERSION}.tar.gz https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxf nginx-${NGINX_VERSION}.tar.gz

RUN mkdir -p /tmp/build/module && \
    cd /tmp/build/module && \
    wget -O ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    tar -zxf ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}.tar.gz && \
    cd ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}

RUN cd /tmp/build/nginx/nginx-${NGINX_VERSION} && \
    patch -p1 < /tmp/build/module/ngx_http_proxy_connect_module-0.0.6/patch/proxy_connect_rewrite_102101.patch

RUN cd /tmp/build/nginx/nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx --group=nginx \
	--with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module \
    --with-http_v2_module --with-http_v3_module \
	--add-module=/tmp/build/module/ngx_http_proxy_connect_module-${NGINX_HTTP_PROXY_CONNECT_MODULE}

RUN cd /tmp/build/nginx/nginx-${NGINX_VERSION} && \
    make -j $prox && \
    make install && \
    mkdir /var/lock/nginx && \
    mkdir -p /var/cache/nginx

RUN adduser --system --no-create-home --shell /bin/false --group --disabled-login nginx    

EXPOSE 80
EXPOSE 443

# COPY nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]   
# nginx -g 'daemon off;'









