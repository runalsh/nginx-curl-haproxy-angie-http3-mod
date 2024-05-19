Nginx with ngx_http_proxy_connect_module and quic-http/3

    Release deb package https://github.com/runalsh/nginx-curl-http3-mod/releases/download/1.25.5-0.0.6/nginx_1.25.5_amd64.deb
    
    /nginx/Dockerfile.alpineopenssl
    alpine openssl version: docker pull runalsh/nginx:{latest,1.**.***,openssl} (12MB)

     /nginx/Dockerfile.alpineboring
    alpine boringssl version: docker pull runalsh/nginx:boringssl (13MB)

    /nginx/Dockerfile.alpinequictls
    alpine quictls version: docker pull runalsh/nginx:quictls (16MB)

    /nginx/Dockerfile.builddeb - make deb, install and run
    debian:12-slim version: docker pull runalsh/nginx:deb (36MB)

Curl  with http/3 (quiche-boringssl)

    /curl/Dockerfile - just build and run 

    alpine:3.16 version: docker pull runalsh/curl:alpine (43MB)
    debian:12-slim version: docker pull runalsh/curl:latest (134MB)

    docker run --rm runalsh/curl curl --version
    docker run --rm runalsh/curl curl -sIL https://blog.cloudflare.com --http3 -H 'user-agent: mozilla' | grep 'HTTP/3'    
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/brotli | grep -i 'content-encoding: br'
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/gzip | grep -i 'content-encoding: gzip'
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/get | grep -i 'HTTP/2'

HAproxy with quicktlls

    alpine:3.16 version: docker pull runalsh/haproxy:alpine (64MB unp - 22MB packed)
    docker run --rm runalsh/haproxy:alpine -vv
    
Angie  with ngx_http_proxy_connect_module , http/3, quicktlls
    
    /angie/angie.dockerfile
    alpine openssl : docker pull runalsh/angie:latest (19MB unp)

    /angie/angieproxy.dockerfile
    alpine with ngx_http_proxy_connect_module: docker pull runalsh/angie:proxy (21MB unp)

    /angie/angieproxyquicktls.dockerfile
    alpine with ngx_http_proxy_connect_module and quicktls: docker pull runalsh/angie:proxy3 (27MB unp)

    /angie/angiedeb2.dockerfile
    debian 12 slim with ngx_http_proxy_connect_module: docker pull runalsh/angie:proxydeb (89mb unp)

    
