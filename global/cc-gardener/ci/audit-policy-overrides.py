#!/usr/bin/env python3
"""Check every gardenPolicy/virtualPolicy string in a values checkout.

Requires yq v4 to parse YAML. Values may be nested in maps/lists or spread across
YAML documents. Invalid candidate files and policy values fail the check; parser
diagnostics are not printed because the values files may also contain credentials.
"""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

KEYS = {"gardenPolicy", "virtualPolicy"}
SPEC = importlib.util.spec_from_file_location("audit_policy_check", Path(__file__).with_name("audit-policy-check.py"))
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


def yaml_documents(text):
    result = subprocess.run(["yq", "-o=json", "-I=0", "."], input=text, text=True, capture_output=True)
    if result.returncode:
        raise ValueError("cannot parse YAML")
    return [json.loads(line) for line in result.stdout.splitlines() if line.strip()]


def overrides(value, location=""):
    if isinstance(value, dict):
        for key, child in value.items():
            child_location = location + "/" + key.replace("~", "~0").replace("/", "~1")
            if key in KEYS:
                yield child_location, child
            else:
                yield from overrides(child, child_location)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from overrides(child, location + "/" + str(index))


def policy_from_value(value):
    # The chart embeds these values as YAML strings using nindent.
    if not isinstance(value, str) or not value.strip():
        raise ValueError("expected a non-empty audit policy YAML string")
    documents = yaml_documents(value)
    if len(documents) != 1:
        raise ValueError("expected exactly one audit Policy document")
    policy = documents[0]
    if (not isinstance(policy, dict) or policy.get("kind") != "Policy"
            or policy.get("apiVersion") != "audit.k8s.io/v1"
            or not isinstance(policy.get("rules"), list) or not policy["rules"]
            or any(not isinstance(rule, dict) for rule in policy["rules"])):
        raise ValueError("expected an audit.k8s.io/v1 Policy with non-empty rules")
    return policy


def raise_walk_error(error):
    raise error


def check(directory):
    root = Path(directory)
    if not root.is_dir():
        print(f"ERROR: values directory does not exist: {root}")
        return 1
    if CHECKER.main([]):
        return 1
    failed, count = False, 0
    try:
        for parent, directories, filenames in os.walk(root, onerror=raise_walk_error):
            directories[:] = sorted(name for name in directories if name != ".git")
            for filename in sorted(filenames):
                if Path(filename).suffix.lower() not in (".yaml", ".yml"):
                    continue
                file = Path(parent) / filename
                label = str(file.relative_to(root))
                try:
                    text = file.read_text()
                    if not any(key in text for key in KEYS):
                        continue
                    documents = yaml_documents(text)
                except (OSError, UnicodeError, ValueError):
                    print(f"ERROR [{label}]: cannot read or parse values YAML")
                    failed = True
                    continue
                for index, document in enumerate(documents, 1):
                    for location, value in overrides(document):
                        policy_label = f"{label}:document-{index}{location}"
                        count += 1
                        try:
                            found = CHECKER.violations(policy_from_value(value))
                        except (ValueError, TypeError, AttributeError, KeyError):
                            print(f"ERROR [{policy_label}]: invalid audit Policy")
                            failed = True
                            continue
                        print(f"{'FAIL' if found else 'ok  '} [{policy_label}]")
                        for violation in found:
                            print(f"       {violation}")
                        failed = failed or bool(found)
    except OSError:
        print("ERROR: cannot traverse values directory or run yq")
        return 1
    print(f"Checked {count} audit policy override(s)")
    return int(failed)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: audit-policy-overrides.py VALUES_DIR")
    sys.exit(check(sys.argv[1]))
