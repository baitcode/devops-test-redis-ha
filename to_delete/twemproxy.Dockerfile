FROM alpine:edge

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --no-cache twemproxy

ENTRYPOINT [ "nutcracker", "-c", "/conf/twemproxy.yaml" ]