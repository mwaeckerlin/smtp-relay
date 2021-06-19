# Simple Postfix SMTP Relay

**Warning:** _Open relay!_
For internal use inside your own services, do not expose to public!

Docker image for unprotected open postfix SMTP relay server.

This very basic image is intended to be used together with any other docker image that requires an SMTP server to send mails. E.g. I use it for [mwaeckerlin/nextcloud](https://hub.docker.com/r/mwaeckerlin/nextcloud), [mwaeckerlin/nodebb](https://hub.docker.com/r/mwaeckerlin/nodebb) or [gitea/gitea](https://hub.docker.com/r/gitea/gitea).

If you need `TLS`, just use [mwaeckerlin/smtp-relay-tls](https://hub.docker.com/r/mwaeckerlin/smtp-relay-tls).

See also:

- [mwaeckerlin/smtp-relay](https://hub.docker.com/r/mwaeckerlin/smtp-relay) for a simple open mail relay
- [mwaeckerlin/smtp-relay-tls](https://hub.docker.com/r/mwaeckerlin/smtp-relay-tls) for a simple open mail relay with tls
- [mwaeckerlin/mailforward](https://hub.docker.com/r/mwaeckerlin/mailforward) for a simple mail forwarder without own inbox
- [mwaeckerlin/postfix](https://hub.docker.com/r/mwaeckerlin/postfix) for a full featured postfix server
