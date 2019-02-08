FROM mwaeckerlin/base
MAINTAINER mwaeckerlin

EXPOSE 25

ENV MAILHOST      "localhost"

ENV CONTAINERNAME "smtp-relay"
RUN apk add --no-cache --purge --clean-protected -u postfix rsyslog \
 && postconf -e 'mynetworks = 127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8' \
 && postconf -e 'smtp_tls_security_level = may' \
 && postconf -e smtpd_banner="\$myhostname ESMTP" \
 && postconf -e mail_spool_directory="/var/spool/mail" \
 && postconf -e mailbox_command="" \
 && postconf -e compatibility_level=2

VOLUME /var/spool/mail

ONBUILD RUN mv /start.sh /start-postfix.sh
ONBUILD ADD start.sh /start.sh
