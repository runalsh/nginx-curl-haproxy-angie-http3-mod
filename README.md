Nginx with ngx_http_proxy_connect_module and quic-http/3 (openssl)

Curl with http/3 (quiche-boringssl)

/nginx/Dockerfile.build - just build and run

/nginx/Dockerfile.builddeb - make deb, install and run

/curl/Dockerfile - just build and run (docker run --rm runalsh/curl curl -sIL https://blog.cloudflare.com --http3 -H 'user-agent: mozilla')
