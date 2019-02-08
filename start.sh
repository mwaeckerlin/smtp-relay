#!/bin/sh

postconf -e "myhostname = ${MAILHOST}"

touch /var/log/mail.log
rsyslogd
postfix start
tail -F /var/log/mail.log
