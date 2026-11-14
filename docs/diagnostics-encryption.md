# Encrypted diagnostics reports

A report has two parts. The generic part (the app version, the system, the connection state, the
settings without secrets) stays readable, so whoever receives the report sees what it is about.
The sensitive part (the config, the logs, the crashes, what the user wrote) is encrypted on the
device when the build has a public key, so only the holder of the private key can open it: not
Sentry, the Telegram bot, a mail server nor anyone reading a public GitHub issue.

The encryption is the standard [age](https://age-encryption.org) format, so no tool of ours is
needed to open it.

## What is in a report

Every way of sending carries the same zip, numbered across reports (`hiddify-001.zip`, `hiddify-002.zip`, …):

```text
diagnostics-<time>/
  README.txt               what is encrypted and what is not, and the list of encrypted files
  metadata.json            generic, readable: build, system, connection, settings without
                           secrets, crash report list, the working folder from the Hiddify one on
  goroutines/              readable: the previous run's goroutine snapshots
  crash_reports/           readable: the core's panics and fatal errors with their stacks
  app/                     readable: the app's own exceptions with their stack traces
  sensitive.encrypted.age  age-encrypted zip of:
    config.json            the running config, servers and keys removed
    logs/                  box.log and the cores' stderr (data/stderr<mode>.log)
    oom_reports/ power_reports/
    app/                   the app's logs, description.txt, the full app-info.json,
                           the background core's own zip
```

The core makes the whole report and encrypts it (`hiddify-core/v2/hcore/diagnostics.go`,
`diagnostics_encryption.go`), so a report the core makes on its own is encrypted the same way as
one the app asks for; the app only adds its own files: `ExtraFiles` (its logs, `app-info.json`,
the user's description) go in the sensitive part, `GenericFiles` (its exceptions with their stack
traces) stay readable. The text is scrubbed of
addresses, links and secrets before it is encrypted.

**Local only** is the only way to get the sensitive part in the clear: it has two buttons,
**Save** (the same file the other ways send) and **Save an unencrypted copy**
(`hiddify-001-unencrypted.zip`, the report's own number, with `sensitive/` as a plain folder) for
the user to look inside.

## Set up once

1. Make a key pair, on a machine you trust:

   ```sh
   age-keygen -o hiddify-diagnostics.key
   # Public key: age1...
   ```

   Keep `hiddify-diagnostics.key` private and backed up: a report encrypted to it can not be
   opened without it.

2. Put the public key (`age1…`) in `hiddify-core/v2/hcore/diagnostics_key.go`, as
   `diagnosticsPublicKey`. A build can also set it without changing the file:
   `-ldflags "-X github.com/hiddify/hiddify-core/v2/hcore.diagnosticsPublicKey=age1…"`.

The app build needs nothing: it asks the core for the report and the core answers whether it is
encrypted (`ExportDiagnosticsResponse.encrypted`).

## What changes in a build with a key

- The Sentry event is tagged `encrypted: true`, and the user's description and the crash text are
  not on the event: they are only in the encrypted part.
- A core whose key is set but is not an `age1…` key makes no report at all
  (`ExportDiagnostics` fails), rather than one in the clear.
- Without a key, the report is the `-unencrypted.zip` for every way.
- `ExportDiagnosticsRequest.unencrypted` asks for the sensitive part in the clear: the app uses it
  for **Save the file → Unencrypted**, and for the background core's zip, which goes inside the
  foreground core's sensitive part and is encrypted with it.

## Open a report

Unzip the report, then decrypt its sensitive part:

```sh
unzip hiddify-001.zip
age -d -i hiddify-diagnostics.key diagnostics-*/sensitive.encrypted.age > sensitive.zip
unzip sensitive.zip -d sensitive
```

The Telegram bot needs the private key to read more than `metadata.json`.

## Change the key

Make a new pair and replace `diagnosticsPublicKey`. Builds made before the change still encrypt
to the old key, so keep the old private key as long as those versions are in use.
