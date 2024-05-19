Nginx 1.25.5 with ngx_http_proxy_connect_module 0.0.6 and quic-http/3

    Release deb package https://github.com/runalsh/nginx-curl-http3-mod/releases/download/1.25.5-0.0.6/nginx_1.25.5_amd64.deb
    
    /nginx/Dockerfile.alpineopenssl
    alpine:3.19 openssl version: docker pull runalsh/nginx:{latest,1.25.5,openssl} (12MB)

     /nginx/Dockerfile.alpineboring
    alpine:3.19 boringssl version: docker pull runalsh/nginx:boringssl (13MB)

    /nginx/Dockerfile.alpinequictls
    alpine:3.19 quictls version: docker pull runalsh/nginx:quictls (16MB)

    /nginx/Dockerfile.builddeb - make deb, install and run
    debian:12-slim version: docker pull runalsh/nginx:deb (36MB)

Curl 8.7.1 with http/3 (quiche-boringssl 0.20.1)

    /curl/Dockerfile - just build and run 

    alpine:3.16 version: docker pull runalsh/curl:alpine (43MB)
    debian:12-slim version: docker pull runalsh/curl:latest (134MB)

    docker run --rm runalsh/curl curl --version
    docker run --rm runalsh/curl curl -sIL https://blog.cloudflare.com --http3 -H 'user-agent: mozilla' | grep 'HTTP/3'    
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/brotli | grep -i 'content-encoding: br'
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/gzip | grep -i 'content-encoding: gzip'
    docker run --rm runalsh/curl curl -sIL https://httpbin.org/get | grep -i 'HTTP/2'

HAproxy 2.9.7 with quicktlls 3.1.5

    alpine:3.16 version: docker pull runalsh/haproxy:alpine (64MB unp - 22MB packed)
    docker run --rm runalsh/haproxy:alpine -vv
    
Angie 1.5.0 with ngx_http_proxy_connect_module 0.0.6 and http/3 (openssl)
    
    /angie/angie.dockerfile
    alpine:3.19 : docker pull runalsh/angie:latest (19MB unp)

    /angie/angieproxy.dockerfile
    alpine:3.19 with ngx_http_proxy_connect_module: docker pull runalsh/angie:proxy (27MB unp)

    /angie/angieproxyquicktls.dockerfile
    alpine:3.19 with ngx_http_proxy_connect_module and quicktls: docker pull runalsh/angie:proxy3 (34MB unp)

    /angie/angiedeb2.dockerfile
    debian 12 slim with ngx_http_proxy_connect_module: docker pull runalsh/angie:proxydeb (89mb unp)

    
