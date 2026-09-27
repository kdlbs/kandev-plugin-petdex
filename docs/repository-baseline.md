# Petdex scaffold status and repository baseline

This repository still contains the Kandev plugin template. The manifest,
module, package, and UI registration use `kandev-plugin-template`; the author
is `your-name-here`. The current demo is not Petdex functionality. Keep these
values unchanged until the owner decides the product identity and attribution.
The release identity guard blocks release preparation and publication while
the placeholders remain. Local builds and package verification are available
for scaffold development.

## SDK source and supported host

`.kandev-sdk-ref` pins Go and frontend SDK source to
`570600439036e81f8e9e1c63f15c4abce8a6c846`, which includes Kandev PR #3943.
CI, packaging, and release workflows use this exact revision. Keep the source
pin separate from the manifest runtime floor.

The manifest keeps `min_kandev_version: "0.86.0"`. The Action API is
additive, and the existing `chat-input-actions` registration selects one
render path: `host.ui.Action` when present, or its legacy Button when absent.
The host owns Action geometry, spacing, focus treatment, and responsive size.
Do not copy those styles into the Action path. Keep rich content in the
existing host overlays. Do not bump `api_version` for Action.

## Checks and release boundary

`make test` runs backend and recipe tests, recipe type checking, the composer
Action fallback test, and negative package, release-version, and release
identity checks. `make verify-package-host` verifies the current platform;
`make verify-package` verifies all five declared binaries, the manifest, UI
bundle, exact package files, and checksums.

The release workflow serializes publications without cancelling an active
release. A manual release validates its candidate before pushing metadata or a
tag. A pushed tag must agree with the manifest, Makefile, package filename,
and packaged manifest before a GitHub release is created. Both paths run Go,
UI, and packaging checks. The identity guard blocks both paths for this
unfinished scaffold.

Do not merge until a stable Kandev release includes PR #3943 and the package
has been validated against that release. Before release, also resolve the
plugin id, module/package identity, display name, and author with the owner.

## Local commands

Use Go 1.26.0, Node 24 (or a version allowed by `package.json`), and a private
sibling Kandev checkout at `.kandev-sdk-ref`. From this repository root run:

```sh
npm ci --ignore-scripts
make check-format
go mod tidy
git diff --exit-code -- go.mod go.sum
make vet
make test
make audit-recipes
make build
make verify-package-host
make verify-package
```

Package validation does not certify host compatibility. Before any release,
install the built archive on a disposable host and check the Action and legacy
paths for focus, keyboard, touch, desktop and phone layouts, and disable and
re-enable behavior.
