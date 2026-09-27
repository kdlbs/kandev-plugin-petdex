#!/bin/sh
set -eu

fail() {
	printf 'release identity verification failed: %s\n' "$1" >&2
	exit 1
}

if [ "$#" -gt 1 ]; then
	fail 'usage: verify-release-identity.sh [REPOSITORY_DIRECTORY]'
fi

repo_dir=${1:-.}
[ -d "$repo_dir" ] || fail "repository directory not found: $repo_dir"
repo_dir=$(CDPATH= cd "$repo_dir" && pwd)

for required in manifest.yaml go.mod Makefile ui/bundle.js; do
	[ -f "$repo_dir/$required" ] || fail "missing required file: $required"
done

manifest_id=$(sed -nE 's/^id: "([^"]+)"$/\1/p' "$repo_dir/manifest.yaml")
display_name=$(sed -nE 's/^display_name: "([^"]+)"$/\1/p' "$repo_dir/manifest.yaml")
author=$(sed -nE 's/^author: "([^"]+)"$/\1/p' "$repo_dir/manifest.yaml")
module_name=$(sed -nE 's/^module ([^[:space:]]+)$/\1/p' "$repo_dir/go.mod")
registered_id=$(sed -nE 's/.*window\.registerKandevPlugin\("([^"]+)".*/\1/p' "$repo_dir/ui/bundle.js")
binary_name=$(sed -nE 's#^BIN := bin/([^[:space:]]+)$#\1#p' "$repo_dir/Makefile")

[ -n "$manifest_id" ] || fail 'manifest.yaml has no plugin id'
[ -n "$author" ] || fail 'manifest.yaml has no author'
[ "$manifest_id" != 'kandev-plugin-template' ] || fail 'manifest still has the template plugin id'
[ "$display_name" != 'Template Plugin' ] || fail 'manifest still has the template display name'
case "$(printf '%s' "$author" | tr '[:upper:]' '[:lower:]')" in
	'your-name-here'|'your name'|'replace me'|'todo'|'tbd'|'unknown')
		fail 'manifest author is still a placeholder'
		;;
esac
[ "$module_name" = "$manifest_id" ] || fail "Go module '$module_name' differs from manifest id '$manifest_id'"
[ "$registered_id" = "$manifest_id" ] || fail "UI registration id '$registered_id' differs from manifest id '$manifest_id'"
[ "$binary_name" = "$manifest_id" ] || fail "binary name '$binary_name' differs from manifest id '$manifest_id'"

manifest_version=$(sed -nE 's/^version: "([0-9]+\.[0-9]+\.[0-9]+)"$/\1/p' "$repo_dir/manifest.yaml")
expected_package="$manifest_id-$manifest_version.tar.gz"
package_file=$(make --no-print-directory -s -C "$repo_dir" package-file) || fail 'could not determine package filename'
[ "$package_file" = "$expected_package" ] || fail "package filename '$package_file' differs from expected '$expected_package'"

printf 'release identity verification passed for %s (%s)\n' "$manifest_id" "$author"
