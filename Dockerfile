FROM mwaeckerlin/very-base as build
RUN mkdir /mail
RUN $ALLOW_USER /mail
RUN apk add --no-cache --purge --clean-protected -u postfix rsyslog
RUN postconf -e 'mynetworks = 127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8'
RUN postconf -e 'smtp_tls_security_level = may'
RUN postconf -e smtpd_banner="\$myhostname ESMTP"
RUN postconf -e mail_spool_directory="/mail"
RUN postconf -e mailbox_command=""
RUN postconf -e compatibility_level=2
RUN postconf -e maillog_file=/dev/stdout
RUN postconf -e inet_interfaces=all

FROM mwaeckerlin/scratch
ENV CONTAINERNAME "smtp-relay"
COPY --from=build / /
EXPOSE 25
VOLUME /mail
USER root
CMD /usr/sbin/postfix start-fg
