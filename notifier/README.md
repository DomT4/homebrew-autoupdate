# Notifier maintenance

`notifier.swift` is the reviewable source for the notification app.
`notify.sh` summarizes only the output from the current autoupdate run and
passes the resulting title, subtitle, and message to the app as arguments.
The native helper uses macOS's UserNotifications framework and runs as a
background UI app, so it does not appear in the Dock.

## Validate without signing

```sh
bash -n notifier/notify.sh notifier/build.sh
xcrun swiftc -swift-version 5 -typecheck notifier/notifier.swift
ruby test/notifier_test.rb
```

CI performs these checks but does not sign or replace the committed app.

## Rebuild and sign locally

Set the identity exactly as shown by `security find-identity -v -p codesigning`:

```sh
CODESIGN_IDENTITY="Developer ID Application: Example (TEAMID)" notifier/build.sh
```

The app version is read from the repository's `VERSION` file, which is also
used by `brew autoupdate --version`.

The build happens in a temporary directory. The committed app is replaced only
after signing and strict verification succeed.
