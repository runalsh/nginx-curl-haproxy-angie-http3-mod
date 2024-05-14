
FROM alpine

ENV ANGIE_VERSION 1.5.0
ENV NGINX_HTTP_PROXY_CONNECT_MODULE 0.0.6

ARG ANGIE_VERSION
ARG NGINX_HTTP_PROXY_CONNECT_MODULE

RUN set -x \
     && apk add --no-cache ca-certificates curl \
     && curl -o /etc/apk/keys/angie-signing.rsa https://angie.software/keys/angie-signing.rsa \
     && echo "https://download.angie.software/angie/alpine/v$(egrep -o \
          '[0-9]+\.[0-9]+' /etc/alpine-release)/main" >> /etc/apk/repositories \
     && apk add --no-cache angie~$ANGIE_VERSION angie-console-light \
     && rm /etc/apk/keys/angie-signing.rsa \
     # && ln -sf /dev/stdout /var/log/angie/access.log \
     # && ln -sf /dev/stderr /var/log/angie/error.log \
     && mkdir -p /var/cache/angie

RUN angie -V

CMD ["angie", "-g", "daemon off;"]