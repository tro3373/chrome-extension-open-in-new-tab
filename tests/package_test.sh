#!/usr/bin/env bash
# Tests for `make build` / `make bump`. Run with `make test`.

root="$(cd "$(dirname "${BASH_SOURCE:-$0}")/.." && pwd)" && readonly root
# setup pins name "Sample Ext" / version 1.2.3, independent of the real manifest
readonly zip="dist/sample-ext-1.2.3.zip"

fail() {
  echo "==> Error: $*" >&2
  exit 1
}

# Each case runs in a throwaway copy so dist/ and manifest.json edits never touch the repo
setup() {
  cp -a "${root}/." "${work}/"
  rm -rf "${work}/dist" "${work}/icons"
  jq '.name = "Sample Ext" | .version = "1.2.3"' "${root}/manifest.json" >"${work}/manifest.json"
  # Files that must never ship. .git is a file in a worktree and a directory otherwise
  [[ -e "${work}/.git" ]] || mkdir "${work}/.git"
  mkdir -p "${work}/.tasks"
  touch "${work}/CLAUDE.md" "${work}/.tasks.md"
}

test_build_creates_zip_named_after_manifest_name_and_version() {
  make build

  [[ -f ${zip} ]] || fail "not created: ${zip}"
}

test_build_puts_extension_files_at_zip_root() {
  local entries f

  make build

  entries=$(unzip -Z1 "${zip}")
  for f in manifest.json background.js content.js README.md; do
    grep -qx "${f}" <<<"${entries}" || fail "not in zip: ${f}"
  done
}

# FILES in the Makefile is a hand-written list; catch it falling behind manifest.json
test_build_includes_every_file_manifest_references() {
  local entries f

  make build

  entries=$(unzip -Z1 "${zip}")
  for f in $(jq -r '.background.service_worker?, .content_scripts[]?.js[]?, (.icons // {} | .[]) | select(. != null)' manifest.json); do
    grep -qx "${f}" <<<"${entries}" || fail "manifest references ${f} but zip lacks it"
  done
}

test_build_leaves_out_claude_md_git_and_tasks() {
  local leaked

  make build

  leaked=$(unzip -Z1 "${zip}" | grep -E '^(CLAUDE\.md|\.git|\.tasks)' || true)
  [[ -z ${leaked} ]] || fail "must not ship: ${leaked}"
}

test_build_includes_icons_when_present() {
  mkdir icons
  touch icons/icon128.png

  make build

  unzip -Z1 "${zip}" | grep -qx 'icons/icon128.png' || fail "icons not in zip"
}

test_bump_increments_last_version_number_only() {
  local before version
  before=$(jq -S 'del(.version)' manifest.json)

  make bump

  version=$(jq -r .version manifest.json)
  [[ ${version} == "1.2.4" ]] || fail "version: ${version}"
  [[ "$(jq -S 'del(.version)' manifest.json)" == "${before}" ]] || fail "keys other than version changed"
}

test_build_after_bump_uses_new_version() {
  make bump

  make build

  [[ -f dist/sample-ext-1.2.4.zip ]] || fail "not created: dist/sample-ext-1.2.4.zip"
}

test_bump_and_build_in_one_make_uses_new_version() {
  make bump build

  [[ -f dist/sample-ext-1.2.4.zip ]] || fail "not created: dist/sample-ext-1.2.4.zip"
  [[ ! -e ${zip} ]] || fail "zip named after the old version: ${zip}"
}

test_bump_changes_only_the_version_line() {
  local changed
  cp manifest.json manifest.before

  make bump

  changed=$(diff manifest.before manifest.json | grep -c '^>' || true)
  [[ ${changed} -eq 1 ]] || fail "changed lines: ${changed}"
}

test_build_rejects_invalid_version_and_leaves_no_zip() {
  jq '.version = "1.02"' manifest.json >manifest.tmp
  mv manifest.tmp manifest.json

  if make build; then
    fail "build accepted version 1.02"
  fi

  [[ -z "$(find dist -name '*.zip' 2>/dev/null)" ]] || fail "zip left behind"
}

run_case() {
  local work out status
  work=$(mktemp -d)
  setup

  # errexit is ignored inside `if` / `||`, so run the case as a plain statement
  set +e
  out=$(
    set -e
    cd "${work}"
    "${fn}" 2>&1
  )
  status=$?
  set -e
  rm -rf "${work}"

  if ((status == 0)); then
    echo "ok   ${fn}"
    return
  fi
  echo "FAIL ${fn}"
  echo "${out}"
  failed=1
}

main() {
  set -euo pipefail

  local fn failed=0
  for fn in $(declare -F | awk '$3 ~ /^test_/ {print $3}'); do
    run_case
  done
  return "${failed}"
}
main "$@"
