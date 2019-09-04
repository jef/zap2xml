FROM alpine:3.10.2

RUN apk add --no-cache \
  perl \
  perl-http-cookies \
  perl-lwp-useragent-determined \
  perl-json \
  perl-json-xs \
  perl-lwp-protocol-https

#RUN echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
#RUN echo "@edgetesting http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
#RUN apk add --no-cache perl@edge perl-html-parser@edge perl-http-cookies@edge perl-lwp-useragent-determined@edge perl-json@edge perl-json-xs@edgetesting
#RUN apk add --no-cache perl-lwp-protocol-https@edge perl-uri@edge ca-certificates@edge perl-net-libidn@edge perl-net-ssleay@edge perl-io-socket-ssl@edge perl-libwww@edge perl-mozilla-ca@edge perl-net-http@edge

VOLUME /data
COPY zap2xml.pl /zap2xml.pl
COPY entry.sh /entry.sh
RUN chmod 755 /entry.sh /zap2xml.pl

CMD ["/entry.sh"]
