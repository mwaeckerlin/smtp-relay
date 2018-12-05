FROM mwaeckerlin/base
MAINTAINER mwaeckerlin

EXPOSE 25

ENV MAILHOST      "localhost"

ENV CONTAINERNAME "smtp-relay"
RUN apk update \
 && apk add postfix rsyslog \
 && postconf -e 'mynetworks = 127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8' \
 && postconf -e 'smtp_tls_security_level = may'

ONBUILD RUN mv /start.sh /start-postfix.sh
ONBUILD ADD start.sh /start.sh
