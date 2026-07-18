# Simple Postfix SMTP Relay

**Warning:** _Open relay!_
For internal use inside your own services, do not expose to public!

Docker image for unprotected open postfix SMTP relay server.

This very basic image is intended to be used together with any other docker image that requires an SMTP server to send mails. E.g. I use it for [mwaeckerlin/nextcloud](https://hub.docker.com/r/mwaeckerlin/nextcloud), [mwaeckerlin/nodebb](https://hub.docker.com/r/mwaeckerlin/nodebb) or [gitea/gitea](https://hub.docker.com/r/gitea/gitea).

If you need `TLS`, just use [mwaeckerlin/smtp-relay-tls](https://hub.docker.com/r/mwaeckerlin/smtp-relay-tls).

## Headless image

The image is headless: a small compiled `init` binary configures
postfix from the environment and execs the postfix `master` daemon in
container mode — there is no shell, no busybox and no package manager
in the shipped image. `init --healthcheck` TCP-probes the SMTP listener
on 127.0.0.1:25 and can be wired as a Docker healthcheck:

```yaml
healthcheck:
  test: ["CMD", "/usr/bin/init", "--healthcheck"]
```

Trade-off: the container starts as root — the postfix master needs it
to bind port 25 and manage the mail queue — and every postfix service
then drops privileges to the unprivileged `postfix` user per master.cf.

## Mail queue persistence

Postfix answers `250 Ok` as soon as a mail is safely written (fsync)
into its queue — from that moment the server owns delivery and the
sender never retries. A deferred mail (target greylisting, target
briefly down) can sit in the queue for hours or days. **Map
`/var/spool/postfix` to a named volume** (see `docker-compose.yml`),
otherwise every container recreate or image update silently destroys
accepted-but-undelivered mail.

## DNS blocklists

The smtpd restrictions include DNSBL/RHSBL lookups (manitu, spamhaus).
Set **`DISABLE_DNSBL`** to any non-empty value to strip them — for
test or offline stacks whose resolver cannot answer the blocklist
zones (each lookup would stall the SMTP dialogue until the resolver
timeout). Trade-off: without the blocklists, known-bad senders are no
longer rejected at connect time; leave it unset in production.

## Delivery-affecting limits

Both limits are deliberately high by default and configurable — a
legitimate mail must never bounce because of an artificial default:

- **`MESSAGE_SIZE_LIMIT`** (bytes, default `107374182400` = 100 GiB,
  `0` = unlimited): maximum accepted message size;
  `mailbox_size_limit` is pinned to the same value.
- **`SMTP_HARD_ERROR_LIMIT`** (default `20`, the postfix standard):
  hard SMTP protocol errors per session before the connection is
  dropped.

See also:

- [mwaeckerlin/smtp-relay](https://hub.docker.com/r/mwaeckerlin/smtp-relay) for a simple open mail relay
- [mwaeckerlin/smtp-relay-tls](https://hub.docker.com/r/mwaeckerlin/smtp-relay-tls) for a simple open mail relay with tls
- [mwaeckerlin/mailforward](https://hub.docker.com/r/mwaeckerlin/mailforward) for a simple mail forwarder without own inbox
- [mwaeckerlin/postfix](https://hub.docker.com/r/mwaeckerlin/postfix) for a full featured postfix server

## SPF, DKIM and DMARC

### SPF (Sender Policy Framework)

SPF is DNS-only — no server-side configuration required. Add a TXT record to your domain:

```
Name:  example.com
Type:  TXT
Value: v=spf1 mx ~all
```

Replace `~all` (softfail) with `-all` (hardfail) once all legitimate senders are listed.

---

### DKIM (DomainKeys Identified Mail)

DKIM signing is optional. Connect this relay to an external OpenDKIM milter via the `OPENDKIM` environment variable:

```yaml
smtp-relay:
  image: mwaeckerlin/smtp-relay
  environment:
    OPENDKIM: opendkim        # host[:port], default port 10026

opendkim:
  image: mwaeckerlin/opendkim
  environment:
    DOMAIN:   example.com    # required
    SELECTOR: mail            # optional, default: mail
  volumes:
    - dkim-keys:/etc/opendkim/keys
```

On first start, OpenDKIM prints the DNS record to publish:

```
Name:  mail._domainkey.example.com
Type:  TXT
Value: v=DKIM1; h=sha256; k=rsa; p=<public-key>
```

To disable DKIM, leave `OPENDKIM` empty or unset.

---

### DMARC (Domain-based Message Authentication, Reporting and Conformance)

DMARC is DNS-only. Add a TXT record:

```
Name:  _dmarc.example.com
Type:  TXT
Value: v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com
```

Start with `p=none` to monitor, then move to `p=quarantine` or `p=reject`.
