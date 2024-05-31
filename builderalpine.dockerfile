FROM alpine:3.20

# RUN apk add --no-cache --virtual .build-deps build-base wget curl ca-certificates gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers pcre-dev wget zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor cmake samurai libunwind-dev linux-headers perl-dev libstdc++  libssl3 libcrypto3 openssl openssl-dev git luajit-dev libxslt-dev pcre
# RUN apk add --no-cache --virtual .build-deps build-base wget ca-certificates gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers pcre-dev wget curl zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor cmake samurai libunwind-dev linux-headers perl-dev libstdc++  libssl3 libcrypto3 openssl openssl-dev git luajit-dev libxslt-dev
# RUN apk add --no-cache --virtual .build-deps autoconf automake brotli-dev build-base cmake libtool nghttp2-dev git pkgconfig wget zlib-dev ca-certificates zlib pcre2 shadow
# RUN apk add --no-cache --virtual .build-deps build-base wget ca-certificates gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers pcre-dev wget zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor cmake samurai libunwind-dev linux-headers perl-dev libstdc++
# RUN apk add --no-cache --virtual .build-deps libssl3 libcrypto3 openssl-dev
# RUN apk add --no-cache --virtual .build-deps build-base wget ca-certificates openssl gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers openssl-dev pcre-dev wget zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor
# RUN apk add --no-cache --virtual .build-deps libxslt-dev perl-dev geoip-dev
# RUN apk add --no-cache --virtual .build-deps build-base wget ca-certificates openssl gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf build-base linux-headers openssl-dev pcre-dev wget zlib-dev ca-certificates uwsgi uwsgi-python3 supervisor
# RUN apk add --no-cache --virtual .build-deps libxslt-dev perl-dev geoip-dev

RUN apk add --no-cache build-base wget curl ca-certificates gnupg unzip make zlib-dev pkgconfig libtool cmake automake autoconf linux-headers pcre-dev uwsgi uwsgi-python3 supervisor samurai libunwind-dev perl-dev libstdc++ libssl3 libcrypto3 openssl openssl-dev git luajit-dev libxslt-dev brotli-dev nghttp2-dev zlib pcre2 shadow










