# Simple Postfix SMTP Relay

**Warning:** _Open relay!_ For internal use inside your own services, do not expose to public!

Docker image for unprotected open postfix SMTP relay server.

This very basic image is intended to be used together with any other docker image that requires an SMTP server to send mails. E.g. I use it for [mwaeckerlin/nextcloud](https://hub.docker.com/r/mwaeckerlin/nextcloud), [mwaeckerlin/nodebb](https://hub.docker.com/r/mwaeckerlin/nodebb) or [gitea/gitea](https://hub.docker.com/r/gitea/gitea).

If you need `TLS`, just use [mwaeckerlin/smtp-relay-tls](https://hub.docker.com/r/mwaeckerlin/smtp-relay-tls).

## Headless image

The image is headless: a small compiled `init` binary configures postfix from the environment and execs the postfix `master` daemon in container mode — there is no shell, no busybox and no package manager in the shipped image. `init --healthcheck` TCP-probes the SMTP listener on 127.0.0.1:25 and can be wired as a Docker healthcheck:

```yaml
healthcheck:
  test: ["CMD", "/usr/bin/init", "--healthcheck"]
```

Trade-off: the container starts as root — the postfix master needs it to bind port 25 and manage the mail queue — and every postfix service then drops privileges to the unprivileged `postfix` user per master.cf.

## Mail queue persistence

Postfix answers `250 Ok` as soon as a mail is safely written (fsync) into its queue — from that moment the server owns delivery and the sender never retries. A deferred mail (target greylisting, target briefly down) can sit in the queue for hours or days. **Map `/var/spool/postfix` to a named volume** (see `docker-compose.yml`), otherwise every container recreate or image update silently destroys accepted-but-undelivered mail.

## The name this relay announces — set it, or the address gets blocklisted

**Postfix greets every receiving server with `myhostname`, and without a name of your own that is the id of the container.** Docker fills the container hostname with the first twelve hex digits of the container id, postfix takes `myhostname` from it, and `smtp_helo_name = $myhostname` sends it out on every connection. A name like `d308e74f098d.localdomain` resolves nowhere.

What that costs, measured on 2026-10-27 on a cluster running this image: Spamhaus listed the sending address on XBL and CSS, with the entry

```
212.51.159.193  2026-10-27 15:15:00  d308e74f098d.localdomain
```

The mail behind it was a calendar invitation from Nextcloud. One listing hits every service behind that address, because the address is what gets listed, not the container.

**Set the name in both places:**

```yaml
smtp:
  image: mwaeckerlin/smtp-relay
  hostname: mail.example.com
  environment:
    MAILHOST: mail.example.com
```

`hostname:` sets the container hostname, which postfix reads; `MAILHOST` writes `myhostname` directly. Either one is enough, both together say it where a reader looks. When neither is set, the start writes a warning naming the container id it is about to announce.

**Which name belongs there: the one the PTR record of the outgoing address carries.** Three values have to agree, and all three are readable:

```
hostname: mail.example.com         in the compose file
dig +short mail.example.com        the address the mail leaves from
dig +short -x <that address>       mail.example.com
```

The address mail leaves from is the public address of the host, or of the NAT router in front of it. The PTR record belongs to whoever owns that address, usually the provider, so the name it carries is the name that goes into the compose file.

Google, Microsoft and Yahoo require that record in their published sender rules: «Ensure that sending domains or IPs have valid forward and reverse DNS records» (Google, [Email sender guidelines](https://support.google.com/mail/answer/81126)), «Have a valid forward and reverse DNS record for your sending IPs» (Yahoo, [Sender Best Practices](https://senders.yahooinc.com/best-practices/)), «Email servers must have valid reverse DNS records» (Microsoft, Outlook.com postmaster policies).

**A correct name alone does not get the mail through.** A relay that delivers directly sends on behalf of your domains, and a receiver asks whether your domain authorises this address. Without SPF, Google answers `5.7.26 unauthenticated mail` and the message bounces. Publish for every sending domain:

```
example.com.  IN TXT  "v=spf1 mx ip4:<the outgoing address> -all"
```

and sign with DKIM through `OPENDKIM` below. The full records are in «SPF, DKIM and DMARC» at the end of this file.

A complete stack with Nextcloud and WordPress sending through this relay is in [`docker-compose.example.yml`](docker-compose.example.yml).

## Relay networks and upstream relay

- **`MYNETWORKS`** (default `127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8`): the client networks allowed to relay through this server, in postfix `mynetworks` syntax. Narrow it to the networks of the services that really send mail.
- **`MAILHOST`** (default empty: postfix uses the container hostname): the name postfix announces to every receiving server. See the section above for which name belongs here.
- **`RELAYHOST`** (default empty: deliver directly to the recipient's MX): `host` or `host:port` of an upstream SMTP server that takes all outbound mail, written to postfix as `relayhost = [host]:port` (no MX lookup). An alternative for whoever runs a mail server of his own: that server then carries the name, the SPF record and the signature, and this relay only hands the mail over.

Pinned by `tests/env-config.sh` (`npm test`), which reads the effective `postconf` value with and without each variable.

## DNS blocklists

The smtpd restrictions include DNSBL/RHSBL lookups (manitu, spamhaus). Set **`DISABLE_DNSBL`** to any non-empty value to strip them — for test or offline stacks whose resolver cannot answer the blocklist zones (each lookup would stall the SMTP dialogue until the resolver timeout). Trade-off: without the blocklists, known-bad senders are no longer rejected at connect time; leave it unset in production.

## Delivery-affecting limits

Both limits are deliberately high by default and configurable — a legitimate mail must never bounce because of an artificial default:

- **`MESSAGE_SIZE_LIMIT`** (bytes, default `107374182400` = 100 GiB, `0` = unlimited): maximum accepted message size; `mailbox_size_limit` is pinned to the same value.
- **`SMTP_HARD_ERROR_LIMIT`** (default `20`, the postfix standard): hard SMTP protocol errors per session before the connection is dropped.

## Input validation

Every environment value is whitelist-validated at start-up before it is fed to `postconf` — a malformed value (embedded newline, stray metacharacters, out-of-range number) aborts the start with a clear `invalid <VAR>` error instead of rendering a broken or unsafe configuration. Pinned by `tests/config-validation.sh` (`npm test`).

See also:

- [mwaeckerlin/smtp-relay](https://hub.docker.com/r/mwaeckerlin/smtp-relay) for a simple open mail relay
- [mwaeckerlin/smtp-relay-tls](https://hub.docker.com/r/mwaeckerlin/smtp-relay-tls) for a simple open mail relay with tls
- [mwaeckerlin/mailforward](https://hub.docker.com/r/mwaeckerlin/mailforward) for a simple mail forwarder without own inbox
- [mwaeckerlin/postfix](https://hub.docker.com/r/mwaeckerlin/postfix) for a full featured postfix server

## SPF, DKIM and DMARC

### SPF (Sender Policy Framework)

SPF is DNS-only — no server-side configuration required. Add a TXT record to your domain:

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
