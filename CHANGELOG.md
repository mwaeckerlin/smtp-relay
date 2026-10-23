# Changelog

- 2026-10-23 **3.5.4**
    - The weekly run also rebuilds the version lines 1 and 2, published as `mwaeckerlin/smtp-relay:1` and `:2` from the branches `1` and `2`, so they get the security fixes of their base images like the line 3

- 2026-10-23 **3.5.3**
    - The version line 3 is published as `mwaeckerlin/smtp-relay:3` from the branch `3`, on every push to it and every week from the run on master, so it gets the security fixes of its base images

- 2026-10-22 **3.5.2**
    - The networks allowed to relay are set with `MYNETWORKS`; unset, the built-in list of loopback and private networks stays
    - `RELAYHOST` sends all outbound mail through one host, written as `host` or `host:port`; unset, the relay delivers directly to the recipient's MX as before
    - A test starts the image and reads the effective postfix configuration for both variables, unset and set

- 2026-09-26 **3.5.1**
    - The image builds on arm64 as well as on amd64 and is published for both under one tag, built and published automatically on every change and every week

- 2026-07-20 **transport-encryption policy for the family**
    - The TLS 1.2 floor now applies only to the mandatory TLS paths (enforced or authenticated connections). Opportunistic inbound and outbound TLS keep every protocol except the broken SSLv2/SSLv3, so a legacy peer's mail is still encrypted rather than forced back to plaintext by a hard floor (delivery before filtering). Inherited by smtp-relay-tls, mailforward and postfix through the image chain.

- 2026-07-18 **security hardening**
    - Every configuration value from the environment is now validated before use; a malformed value (for example an embedded newline that could smuggle extra configuration directives) refuses to start with a clear `invalid <VAR>` error instead of silently producing a broken or unsafe configuration. Covered by the new config-validation test suite (`npm test`).
    - The standalone compose example now binds the relay to loopback only and carries a healthcheck — an open relay must never be published beyond the local machine (see the README warning).

- 2026-07-18 **headless image**
    - The image no longer contains a shell, busybox or a package manager: a compiled `init` binary configures postfix from the environment and starts the postfix master daemon directly. The behaviour (open relay for internal networks, optional `OPENDKIM` milter) is unchanged.
    - New `init --healthcheck` probe for Docker healthchecks.
    - Delivery-affecting limits are now configurable with high defaults: `MESSAGE_SIZE_LIMIT` (default 100 GiB, was postfix's 10 MB default) and `SMTP_HARD_ERROR_LIMIT` (default 20) — a legitimate mail is never bounced by an artificial default.
    - The unused rsyslog package is no longer installed; postfix has been logging to stdout all along (`maillog_file=/dev/stdout`).
    - New `DISABLE_DNSBL` switch (default off) strips the DNS-blocklist lookups from the smtpd restrictions — for test/offline stacks whose resolver cannot answer the blocklist zones.
    - The mail queue (`/var/spool/postfix`) is now a declared volume: an accepted mail (`250 Ok`) is the server's responsibility and the sender never retries — a deferred mail must survive container recreates and image updates. The compose example maps it to a named volume.
