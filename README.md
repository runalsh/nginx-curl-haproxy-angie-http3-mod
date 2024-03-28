Nginx 1.25.4 with ngx_http_proxy_connect_module 0.0.6 and quic-http/3 (openssl) 

    Release deb package https://github.com/runalsh/nginx-curl-http3-mod/releases/download/1.25.4-0.0.6/nginx_1.25.4-1.bookworm_amd64.deb
    /nginx/Dockerfile.alpine
    alpine:3.16 version: docker pull runalsh/nginx-mod:alpine (16MB)
    /nginx/Dockerfile.build - just build and run
    debian:12-slim version: docker pull runalsh/nginx-mod:build (400MB :O)
    /nginx/Dockerfile.builddeb - make deb, install and run
    debian:12-slim version: docker pull runalsh/nginx-mod:deb (98MB)

Curl 8.7.1 with http/3 (quiche-boringssl 0.20.1)

    /curl/Dockerfile - just build and run 

    alpine:3.16 version: docker pull runalsh/curl:alpine (43MB)
    debian:12-slim version: docker pull runalsh/curl:latest (134MB)

    docker run --rm runalsh/curl curl --version
    docker run --rm runalsh/curl curl -sIL https://blog.cloudflare.com --http3 -H 'user-agent: mozilla' | grep 'HTTP/3'    
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/brotli | grep -i 'content-encoding: br'
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/gzip | grep -i 'content-encoding: gzip'
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/get | grep -i 'HTTP/2'
