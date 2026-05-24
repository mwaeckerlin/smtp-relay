#!/bin/sh -e

# DKIM signing via external opendkim milter (optional)
# Set OPENDKIM=host or OPENDKIM=host:port (default port: 10026)
if [ -n "${OPENDKIM}" ] && [ "${OPENDKIM}" = "${OPENDKIM%:*}" ]; then
    OPENDKIM="${OPENDKIM}:10026"
fi
if [ -n "${OPENDKIM}" ]; then
    postconf -e "smtpd_milters=inet:${OPENDKIM}"
    postconf -e "non_smtpd_milters=inet:${OPENDKIM}"
    postconf -e "milter_default_action=accept"
    postconf -e "milter_protocol=6"
    echo "**** OpenDKIM milter: inet:${OPENDKIM}"
fi

exec /usr/sbin/postfix start-fg
