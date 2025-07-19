FROM alpine:3.22.1

RUN apk add --no-cache \
  perl \
  perl-http-cookies \
  perl-lwp-useragent-determined \
  perl-json \
  perl-json-xs \
  perl-lwp-protocol-https \
  perl-gd

WORKDIR /opt

COPY zap2xml.pl zap2xml.pl
COPY entrypoint.sh entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
