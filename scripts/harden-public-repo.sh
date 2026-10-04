#!/usr/bin/env bash
# Standing rule: public repos are for viewing, not collaboration.
# Anyone may open issues; only the owner and their agents create branches/PRs/changes.
# Usage: harden-public-repo.sh OWNER/REPO   (idempotent; run right after creating a public repo; never weakens existing branch protection)
set -euo pipefail
repo="${1:?usage: $0 OWNER/REPO}"
vis=$(gh api "repos/$repo" --jq .visibility)
[ "$vis" = "public" ] || { echo "$repo is $vis, not public: nothing to do"; exit 0; }

gh api -X PATCH "repos/$repo" -f pull_request_creation_policy=collaborators_only \
  -F has_wiki=false -F has_projects=false >/dev/null
branch=$(gh api "repos/$repo" --jq .default_branch)
# Branch protection is a whole-object PUT: re-running it must never replace stronger rules (required reviews or checks)
# with weaker ones. So: no protection yet -> set the floor; protection exists -> leave it alone and only report.
if existing=$(gh api "repos/$repo/branches/$branch/protection" 2>/dev/null); then
  force=$(printf '%s' "$existing" | python3 -c 'import json,sys;print(json.load(sys.stdin)["allow_force_pushes"]["enabled"])')
  dele=$(printf '%s' "$existing" | python3 -c 'import json,sys;print(json.load(sys.stdin)["allow_deletions"]["enabled"])')
  if [ "$force" != "False" ] || [ "$dele" != "False" ]; then
    echo "WARNING: $repo/$branch already has branch protection that allows force-push or deletion; not changing it automatically" >&2
    echo "         (that would replace your other rules). Turn both off in Settings > Branches." >&2
  fi
else
  tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
  cat >"$tmp" <<JSON
{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":null,
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
JSON
  gh api -X PUT "repos/$repo/branches/$branch/protection" --input "$tmp" >/dev/null
fi
gh api -X PUT "repos/$repo/vulnerability-alerts" >/dev/null || true
gh api -X PUT "repos/$repo/automated-security-fixes" >/dev/null || true
# private vulnerability reporting: reporters use GitHub Security Advisories instead of public issues
gh api -X PUT "repos/$repo/private-vulnerability-reporting" >/dev/null 2>&1 || echo "note: could not enable private vulnerability reporting (needs admin; enable it in Settings > Security)" >&2

echo "== $repo"
gh api "repos/$repo" --jq '"issues=\(.has_issues) wiki=\(.has_wiki) projects=\(.has_projects) pr_creation=\(.pull_request_creation_policy) secret_scanning=\(.security_and_analysis.secret_scanning.status) push_protection=\(.security_and_analysis.secret_scanning_push_protection.status) dependabot=\(.security_and_analysis.dependabot_security_updates.status)"'
pvr=$(gh api "repos/$repo/private-vulnerability-reporting" --jq .enabled 2>/dev/null || echo unknown)
echo "private_vulnerability_reporting=$pvr"
gh api "repos/$repo/branches/$branch/protection" --jq '"main: force_push=\(.allow_force_pushes.enabled) deletions=\(.allow_deletions.enabled)"'
echo "collaborators: $(gh api "repos/$repo/collaborators" --jq '[.[].login]|join(",")')"
