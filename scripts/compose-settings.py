#!/usr/bin/env python3
"""Compose a Claude Code settings fragment from policies/claude/rules.json.

  compose-settings.py ROLE [standard|permissive]        print the fragment as JSON
  compose-settings.py --merge-into FILE ROLE [POSTURE] [--replace]
                                                        merge it into an existing settings file (idempotent);
                                                        --replace first drops every rule this template could have added
                                                        (so switching permissive -> standard really narrows), keeping yours

ROLE is one of dev, review, watch, monitor. The fragment always carries the full deny list.
Permissive only widens what a *builder* may do without a prompt; read-only roles never widen.
Merging adds rules and never removes or reorders existing ones; a defaultMode already set in the
target is kept (the operator's explicit choice wins) unless the target has none.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RULES = os.path.join(HERE, "..", "policies", "claude", "rules.json")


def compose(role, posture):
    rules = json.load(open(RULES))
    if role not in rules["roles"]:
        sys.exit(f"unknown role '{role}' (one of: {', '.join(rules['roles'])})")
    if posture not in ("standard", "permissive"):
        sys.exit("posture must be standard or permissive")
    r = rules["roles"][role]
    deny = list(dict.fromkeys(rules["deny"] + r["extra_deny"]))
    allow = [a for a in r["allow"][posture] if a not in deny]
    return {"permissions": {"defaultMode": r["defaultMode"], "allow": allow, "deny": deny}}


def ours():
    """Every allow and deny rule this template can generate, for --replace."""
    rules = json.load(open(RULES))
    allow = {a for r in rules["roles"].values() for lst in r["allow"].values() for a in lst}
    deny = set(rules["deny"]) | {x for r in rules["roles"].values() for x in r["extra_deny"]}
    return allow, deny


def merge(target, frag, replace=False):
    cur = json.load(open(target)) if os.path.exists(target) else {}
    perms = cur.setdefault("permissions", {})
    if replace:
        a, d = ours()
        perms["allow"] = [x for x in perms.get("allow", []) if x not in a]
        perms["deny"] = [x for x in perms.get("deny", []) if x not in d]
    for key in ("allow", "deny"):
        have = perms.setdefault(key, [])
        for rule in frag["permissions"][key]:
            if rule not in have:
                have.append(rule)
    perms.setdefault("defaultMode", frag["permissions"]["defaultMode"])
    return cur


def main(argv):
    if len(argv) >= 3 and argv[0] == "--merge-into":
        replace = "--replace" in argv
        argv = [a for a in argv if a != "--replace"]
        target, role = argv[1], argv[2]
        posture = argv[3] if len(argv) > 3 else "standard"
        out = merge(target, compose(role, posture), replace)
        os.makedirs(os.path.dirname(os.path.abspath(target)), exist_ok=True)
        text = json.dumps(out, indent=2) + "\n"
        if not os.path.exists(target) or open(target).read() != text:
            open(target, "w").write(text)
        return
    if not argv:
        sys.exit(__doc__)
    print(json.dumps(compose(argv[0], argv[1] if len(argv) > 1 else "standard"), indent=2))


if __name__ == "__main__":
    main(sys.argv[1:])
