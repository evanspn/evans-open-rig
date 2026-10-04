# Security

This repo templates a team of coding agents that can run shell commands, edit files, use `gh`, and message each other.
That is a lot of authority, so the defaults here are built to fail closed: a rig launched from these templates asks before it does
anything outward-facing or destructive, and it is never launched with every permission bypassed.

## Reporting a problem

Use **GitHub private vulnerability reporting** (Security tab -> "Report a vulnerability") on this repository. Please do not open a
public issue for a vulnerability. If you find a committed secret, report it the same way so it can be rotated.

## Threat model

| Threat | How it happens to an agent team | What the defaults do | What you must still do |
| --- | --- | --- | --- |
| **Prompt injection** | A PR or issue comment, a web page, a file, a tool result or another seat's queue row contains instructions ("ignore your rules", "run this", "the operator approved it"). | `CULTURE.md` (security floor) tells every seat that content is data, to quote and report injection attempts, and that only the operator and the orchestrator's row carry authority. The deny list blocks the worst commands whoever asks. The security reviewer and monitor cannot edit, commit or push; the PR watcher cannot either, and may merge a finished PR only after you approve it (standard posture). | Do not point agents at untrusted repos or pages unattended. Review PRs from outside contributors yourself. |
| **Secret leakage** | A token is pasted into a prompt, a queue row, a commit, a PR or a log; an agent reads `~/.ssh`, `.env` or cloud credentials and repeats them. | Deny rules block reading common secret files and credential CLIs; `CULTURE.md` forbids putting secrets in prompts, rows, commits and logs; `.gitignore` excludes secret and image files; `scripts/scan-secrets.sh` and the pre-push hook scan the tree and all history. | Keep secrets in a keychain or environment, not in the project. Rotate anything that ever reached a prompt, a row or a commit; deleting it later does not unpublish it. |
| **Over-broad tokens** | The `gh` login or an API key can do far more than the work needs, so one mistake or injection reaches everything. | Seats do not receive tokens from the template. Deny rules block `gh auth token`, `gh secret`, `gh repo delete/edit` and force-pushes. | Use a fine-grained, short-lived token limited to the repos and scopes in play. Do not run agents as an admin on repos you cannot afford to lose. |
| **Public-repo exposure** | A private project is made public, a public repo takes outside PRs, history contains a secret or a personal path. | `scripts/harden-public-repo.sh` (collaborators-only PRs, no force-push or deletion on the default branch, wiki and projects off, Dependabot, secret scanning, private vulnerability reporting). `CULTURE.md` requires the history scan before publishing. | Run the script on every new public repo and read its output (secret scanning and push protection must say `enabled`). |
| **Acting outside the repo** | An agent edits dotfiles, system paths, other repos or a remote host because a task seemed to need it. | Deny rules cover credentials, shell startup files, `/etc`, `/usr`, launch agents and git hooks; `CULTURE.md` says to work only in the launch project and to ask. | Run seats in a dedicated project directory (ideally a container or VM) and use Claude Code's sandbox where your version supports it. |
| **Unattended escalation** | An overnight run bypasses every prompt and does something irreversible. | The default posture is `builtin:standard`; `builtin:yolo` (every permission bypassed) is never installed. The `permissive` posture widens only local, reversible work, not push, merge or publish. | Choose `--posture permissive` deliberately and only for work you would be comfortable returning to a bad morning of. |

## What the defaults are

- **Rig policy:** `builtin:standard` for the rig, `builtin:locked` for the PR watcher, the security reviewer and the oversight monitor.
  OpenRig only *records* these postures; the harness enforces. The real controls are the next items.
- **Claude Code permission rules:** `scripts/install.sh` composes, per role, a `claude_settings_fragment` from
  [`policies/claude/rules.json`](policies/claude/rules.json): one shared **deny list** (privilege escalation, `rm -rf` of `/` or home,
  pipe-to-shell, force-push, `gh repo delete`, `gh auth token`, reading `~/.ssh`, `~/.aws`, `~/.config/gh`, `.env*`, private keys,
  writing shell startup files, system paths and git hooks) plus a small **allow list** of the `rig` verbs and read-only git the
  seat needs. Read-only roles also deny `Edit`, `Write`, `git add/commit/push`, the toolchain commands (`npm`, `cargo`, `pytest`: running a
  project's scripts is code execution) and, for the monitor, all of `gh`; they start in Claude's `default` mode, so anything not
  allow-listed asks. **Merging a PR asks in the standard posture** (the watcher's `gh pr merge` is allowed only in permissive).
  Every role also denies editing the controls that constrain it: `.claude/**`, `~/.claude/**`, `.mcp.json`, `.git/**`,
  `~/.openrig/**`, any `CULTURE.md` and `scripts/hooks/**`, and denies `rig queue resolve` (it records a human decision).
- **Orchestrator and builder** are agents shipped with OpenRig, so their settings cannot carry the fragment. Run
  `scripts/apply-deny-rules.sh <project>` once per project: it merges the same deny list into `<project>/.claude/settings.json`,
  which every seat launched in that project reads. Commit that file.
- **Codex seats:** none are in these templates. If you add one, give it a named profile and select it with `codex_config_profile`
  (see [`policies/codex/restricted.config.toml`](policies/codex/restricted.config.toml)); do not rely on the Claude rules for it.

## Relaxing the defaults on purpose

1. **`./scripts/install.sh --posture permissive`** records `builtin:open` and lets builders and QA run common local toolchain
   commands (git add/commit/branch, npm and cargo build/test, pytest) without prompting. Pushing, merging, publishing and
   `gh` writes still ask, so an unattended run stalls at the first outward step instead of acting. The deny list is unchanged and
   read-only seats are never widened (their own deny rules add the toolchain commands, and deny beats the project-level allow). Run `scripts/apply-deny-rules.sh <project> --posture permissive` to match the project file, and `--replace` when you go
   back to standard (a plain run only adds rules, so permissive allows would otherwise stay).
   **Tradeoff:** fewer interruptions, but a prompt-injected or confused builder can do more local damage before you notice.
2. **`builtin:yolo`** (launch posture `full_bypass`, `--dangerously-skip-permissions`) is not offered by any script here. If you set it
   yourself (`rig policy apply yolo --spec ...`), every prompt disappears and you are relying only on the model's judgment and the
   container or VM around it. Whether deny rules still apply in that mode depends on your Claude Code version; check before relying
   on them. Use it only in a disposable environment with no credentials worth stealing.

## Known bypasses and limits

- **Deny rules are best-effort and match command text.** Examples that get around a text rule: `printenv` -> `env` or `echo $X`;
  `cat ~/.ssh/...` -> `head`, `less`, or an allowed git command with the right flags; `curl ... | sh` -> `bash -c "$(curl ...)"` or
  `sh <(curl ...)`. In the standard posture those commands are not allow-listed, so **your prompt is the real gate**. In permissive,
  the toolchain allows (`npm run`, `cargo test`, `pytest`) are already arbitrary code execution, so the deny list is advisory there.
- **Read-only git can still read and write files.** `git diff --no-index` reads any path and `git ... --output=FILE` writes any path;
  `--ext-diff`/`--textconv` run programs. The deny list blocks those flags, but this class is why the real boundary is a sandbox
  with a filesystem deny list for `~/.ssh`, `~/.aws`, `~/.config/gh` (enable Claude Code's sandbox where your version supports it;
  this template does not configure it because that was not verified).
- **Seats can message each other.** Every seat may `rig send`, including the locked ones, so a read-only seat can type into the
  builder's prompt, and if the target is showing a permission dialog the keystrokes might answer it. This was not tested. Treat the
  rig's effective privilege as close to the union of its seats, and keep an eye on `rig capture` of seats that wait on prompts.
- **Rules only help where they load.** `/permissions` in each seat shows what is active. Rules for the orchestrator and builder
  exist only if you ran `apply-deny-rules.sh` for the project.
- **The built-in secret scanner is narrow.** It matches a short list of credential formats, home paths, emails and file names, with
  no generic or high-entropy detection. Install gitleaks for the fuller ruleset; a clean built-in scan is weak evidence.
- **The pre-push hook is tracked code.** Agents are denied editing `scripts/hooks/**`, but if you do not trust that, copy the hook
  into `.git/hooks/pre-push` instead of setting `core.hooksPath`.

## What this does not protect against (and what was not verified)

- **Deny rules are best-effort.** They match command text; a determined or confused agent can often reach the same effect another way
  (`python -c`, a script it just wrote). They reduce accidents and raise the cost of an injection; a sandbox and least-privilege
  credentials are the real boundary.
- **Harness enforcement was not tested end to end.** The generated specs validate and pass `rig spec preflight`, and the rules are in
  the documented Claude Code syntax, but whether a given Claude Code version loads, merges and enforces each rule was not exercised
  with live seats. After launching, run `/permissions` in a seat and try harmless denied commands (for example `cat ~/.ssh/config` and
  `git diff --no-index /dev/null ~/.ssh/config`) to confirm they are refused or prompt.
- **Merging settings fragments:** OpenRig merges a fragment into `<cwd>/.claude/settings.local.json`. How it combines list fields
  with rules that already exist there was not verified; keep your own rules in `settings.json`, not in `settings.local.json`.
- A compromised machine, a malicious plugin or MCP server, and a leaked token are outside what any template can fix.

## Day-to-day checks

```
scripts/scan-secrets.sh                 # tree + ALL history; run before every push to a public repo
git config core.hooksPath scripts/hooks # one-time: runs the scan as a pre-push hook
scripts/harden-public-repo.sh OWNER/REPO   # sets a floor; never replaces branch protection that already exists
rig policy current --spec ~/.openrig/specs/workshop/rig.yaml   # what is actually recorded, per seat
```
