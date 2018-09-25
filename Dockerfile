FROM mwaeckerlin/base
MAINTAINER mwaeckerlin

ENV CONTAINERNAME "postfix"
RUN apk update \
 && apk add postfix rsyslog \
 && postconf -e 'mynetworks = 127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8'
