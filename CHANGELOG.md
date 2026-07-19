# Changelog

- 2026-07-18 **security hardening**
    - Every configuration value from the environment is now validated
      before use; a malformed value (for example an embedded newline
      that could smuggle extra configuration directives) refuses to
      start with a clear `invalid <VAR>` error instead of silently
      producing a broken or unsafe configuration. Covered by the new
      config-validation test suite (`npm test`).
    - The standalone compose example now binds the relay to loopback
      only and carries a healthcheck — an open relay must never be
      published beyond the local machine (see the README warning).

- 2026-07-18 **headless image**
    - The image no longer contains a shell, busybox or a package
      manager: a compiled `init` binary configures postfix from the
      environment and starts the postfix master daemon directly. The
      behaviour (open relay for internal networks, optional `OPENDKIM`
      milter) is unchanged.
    - New `init --healthcheck` probe for Docker healthchecks.
    - Delivery-affecting limits are now configurable with high
      defaults: `MESSAGE_SIZE_LIMIT` (default 100 GiB, was postfix's
      10 MB default) and `SMTP_HARD_ERROR_LIMIT` (default 20) — a
      legitimate mail is never bounced by an artificial default.
    - The unused rsyslog package is no longer installed; postfix has
      been logging to stdout all along (`maillog_file=/dev/stdout`).
    - New `DISABLE_DNSBL` switch (default off) strips the DNS-blocklist
      lookups from the smtpd restrictions — for test/offline stacks
      whose resolver cannot answer the blocklist zones.
    - The mail queue (`/var/spool/postfix`) is now a declared volume:
      an accepted mail (`250 Ok`) is the server's responsibility and
      the sender never retries — a deferred mail must survive container
      recreates and image updates. The compose example maps it to a
      named volume.
