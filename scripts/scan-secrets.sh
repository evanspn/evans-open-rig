#!/usr/bin/env bash
# Scan this repository's working tree AND all git history for secrets and personal data.
#
#   scripts/scan-secrets.sh            exit 0 if clean, 1 if anything is found, 2 on a usage or environment error
#
# Two layers, both fully local (no network access at scan time):
#   1. gitleaks, if installed (brew install gitleaks), with .gitleaks.toml, over the history and the tree.
#   2. A built-in scanner that needs only git: credential patterns, personal home paths, email addresses, and
#      image/key/.env file names, across every commit on every ref and the current tree.
# Findings print as COMMIT:FILE:LINE (or FILE:LINE for the tree); the matched text is never printed.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not inside a git repository" >&2; exit 2; }
status=0

if command -v gitleaks >/dev/null 2>&1; then
  echo "== gitleaks (history)"
  if gitleaks git --help >/dev/null 2>&1; then
    gitleaks git --config .gitleaks.toml --redact --no-banner . || status=1
    echo "== gitleaks (working tree)"
    gitleaks dir --config .gitleaks.toml --redact --no-banner . || status=1
  else
    gitleaks detect --source . --config .gitleaks.toml --redact --no-banner || status=1
    gitleaks detect --source . --config .gitleaks.toml --redact --no-banner --no-git || status=1
  fi
else
  echo "WARNING: gitleaks is not installed. Only the built-in scanner runs: a narrow set of credential patterns with no generic or" >&2
  echo "         high-entropy detection, so a passing result is weaker evidence. Install gitleaks (brew install gitleaks) and re-run." >&2
fi

echo "== built-in scan: credentials and personal data in all history and the tree"
revfile="$(mktemp)"; trap 'rm -f "$revfile" "$revfile".*' EXIT
git rev-list --all > "$revfile" 2>/dev/null || { echo "SCAN ERROR: git rev-list failed" >&2; exit 2; }
[ -s "$revfile" ] || echo HEAD > "$revfile"
split -l 200 "$revfile" "$revfile."   # batches keep the argument list far below the OS limit
# git grep exits 0 (match), 1 (no match) or >1 (error). An error must never read as "clean".
grep_history() {
  local re="$1" batch out rc
  for batch in "$revfile".??; do
    out="$(git grep -I -n -E -e "$re" $(cat "$batch") -- 2>&1)"; rc=$?
    if [ "$rc" -gt 1 ]; then echo "SCAN ERROR: git grep failed (exit $rc): $(printf '%s' "$out" | head -1 | cut -c1-120)" >&2; exit 2; fi
    [ "$rc" = 0 ] && printf '%s\n' "$out"
  done
  out="$(git grep -I -n -E -e "$re" --untracked -- 2>&1)"; rc=$?
  if [ "$rc" -gt 1 ]; then echo "SCAN ERROR: git grep (tree) failed (exit $rc)" >&2; exit 2; fi
  [ "$rc" = 0 ] && printf '%s\n' "$out"
  return 0
}
# label|extended regex
patterns=(
  "private key|-----BEGIN [A-Z ]*PRIVATE KEY-----"
  "AWS access key|AKIA[0-9A-Z]{16}"
  "GitHub token|gh[pousr]_[A-Za-z0-9]{36,}"
  "GitHub fine-grained token|github_pat_[A-Za-z0-9_]{20,}"
  "Slack token|xox[abprs]-[A-Za-z0-9-]{10,}"
  "API key (sk- prefix)|sk-[A-Za-z0-9_-]{20,}"
  "Google API key|AIza[0-9A-Za-z_-]{35}"
  "hard-coded secret assignment|(password|passwd|secret|api[_-]?key|token)[\"']?[[:space:]]*[:=][[:space:]]*[\"'][^\"' ]{12,}[\"']"
  "personal home path|/(Users|home)/[A-Za-z0-9._-]{2,}/"
  "email address|[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\\.[A-Za-z]{2,}"
)
# addresses that are fine to appear: GitHub noreply, RFC 2606 example domains
allow_email='@(users\.noreply\.github\.com|noreply\.github\.com|example\.(com|org|net))|noreply@anthropic\.com'

# print where it is (commit, file, line) and never the matched text
locate() { awk -F: '{ if ($1 ~ /^[0-9a-f]{40}$/) print substr($1,1,8) ":" $2 ":" $3; else print $1 ":" $2 }'; }

for entry in "${patterns[@]}"; do
  label="${entry%%|*}"; re="${entry#*|}"
  # history: every blob on every ref; tree: tracked and untracked-not-ignored files
  hits="$(grep_history "$re" | sort -u)"; [ "${PIPESTATUS[0]}" = 0 ] || exit 2
  if [ "$label" = "email address" ]; then
    hits="$(printf '%s\n' "$hits" | grep -v -E "$allow_email" || true)"
  fi
  # the scanner itself and the gitleaks rule necessarily spell out the patterns
  hits="$(printf '%s\n' "$hits" | grep -v -E '(^|:)(scripts/scan-secrets\.sh|\.gitleaks\.toml):' || true)"
  hits="$(printf '%s\n' "$hits" | sed '/^$/d')"
  if [ -n "$hits" ]; then
    status=1
    echo "FOUND $label:"
    printf '%s\n' "$hits" | head -20 | locate | sed 's/^/  /'
  fi
done

echo "== built-in scan: file names that should not be in a public repo"
bad="$(git log --all --name-only --format= | sort -u | grep -i -E '\.(png|jpe?g|gif|webp|heic|avif|bmp|tiff?|mov|mp4|pem|p12|pfx|key|keystore)$|(^|/)\.env($|\.)|(^|/)id_(rsa|ed25519)|(^|/)credentials' | grep -v -E '\.env\.example$' || true)"
if [ -n "$bad" ]; then
  status=1
  echo "FOUND files (in history):"
  printf '%s\n' "$bad" | head -20 | sed 's/^/  /'
fi

echo "== identities in history (expect only noreply or a handle you are happy to publish)"
git log --all --format='%an <%ae>' | sort -u | sed 's/^/  /'

if [ "$status" = 0 ]; then echo "CLEAN: nothing found in the tree or in any commit."; else echo "NOT CLEAN: fix the above (a committed secret must be rotated, not only removed)."; fi
exit "$status"
