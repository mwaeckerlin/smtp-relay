#!/bin/sh

postconf -e "myhostname = ${MAILHOST}"

rsyslogd
postfix start
tail -f /var/log/maillog
