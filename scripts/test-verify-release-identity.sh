#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
verify_script=$repo_dir/scripts/verify-release-identity.sh
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

create_fixture() {
	fixture=$1
	mkdir -p "$fixture/ui"
	cat > "$fixture/manifest.yaml" <<'EOF'
id: "kandev-plugin-petdex"
version: "1.2.3"
display_name: "Petdex"
author: "Petdex Maintainers"
EOF
	cat > "$fixture/go.mod" <<'EOF'
module kandev-plugin-petdex
EOF
	cat > "$fixture/Makefile" <<'EOF'
BIN := bin/kandev-plugin-petdex
VERSION := 1.2.3

.PHONY: package-file
package-file:
	@printf '%s\n' "$(notdir $(BIN))-$(VERSION).tar.gz"
EOF
	cat > "$fixture/ui/bundle.js" <<'EOF'
window.registerKandevPlugin("kandev-plugin-petdex", {});
EOF
}

expect_failure() {
	name=$1
	fixture=$2
	if sh "$verify_script" "$fixture" >"$test_dir/output" 2>&1; then
		printf 'expected release identity verification to reject %s\n' "$name" >&2
		exit 1
	fi
}

valid=$test_dir/valid
create_fixture "$valid"
sh "$verify_script" "$valid" >/dev/null

for case_name in template-id template-name placeholder-author mismatched-module mismatched-ui mismatched-binary; do
	fixture=$test_dir/$case_name
	cp -R "$valid" "$fixture"
	case "$case_name" in
		template-id)
			sed 's/kandev-plugin-petdex/kandev-plugin-template/g' "$fixture/manifest.yaml" > "$fixture/manifest.next"
			mv "$fixture/manifest.next" "$fixture/manifest.yaml"
			;;
		template-name)
			sed 's/display_name: "Petdex"/display_name: "Template Plugin"/' "$fixture/manifest.yaml" > "$fixture/manifest.next"
			mv "$fixture/manifest.next" "$fixture/manifest.yaml"
			;;
		placeholder-author)
			sed 's/author: "Petdex Maintainers"/author: "your-name-here"/' "$fixture/manifest.yaml" > "$fixture/manifest.next"
			mv "$fixture/manifest.next" "$fixture/manifest.yaml"
			;;
		mismatched-module)
			sed 's/kandev-plugin-petdex/example-module/' "$fixture/go.mod" > "$fixture/go.next"
			mv "$fixture/go.next" "$fixture/go.mod"
			;;
		mismatched-ui)
			sed 's/kandev-plugin-petdex/example-plugin/' "$fixture/ui/bundle.js" > "$fixture/ui/bundle.next"
			mv "$fixture/ui/bundle.next" "$fixture/ui/bundle.js"
			;;
		mismatched-binary)
			sed 's/BIN := bin\/kandev-plugin-petdex/BIN := bin\/example-plugin/' "$fixture/Makefile" > "$fixture/Makefile.next"
			mv "$fixture/Makefile.next" "$fixture/Makefile"
			;;
	esac
	expect_failure "$case_name" "$fixture"
done

printf 'release identity negative tests passed\n'
