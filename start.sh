#!/bin/sh

rsyslogd
postfix start
tail -f /var/log/maillog
