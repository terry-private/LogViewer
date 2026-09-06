#!/usr/bin/env python3
"""dump-packageからテストターゲット名を取得する。"""

import json
import re
import sys
import xml.etree.ElementTree as ET


def test_targets(package):
    names = [target["name"] for target in package["targets"] if target["type"] == "test"]
    if not names:
        raise ValueError("テストターゲットがありません")
    if any(not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_]+", name) for name in names):
        raise ValueError("テストターゲット名に未対応の文字が含まれています")
    if len(names) != len(set(names)):
        raise ValueError("テストターゲット名が重複しています")
    return names


def validate_scheme(names, path):
    root = ET.parse(path).getroot()
    enabled = [reference.find("BuildableReference").get("BlueprintIdentifier")
               for reference in root.findall("./TestAction/Testables/TestableReference")
               if reference.get("skipped") == "NO"]
    if set(enabled) != set(names) or len(enabled) != len(names):
        raise ValueError("Package.swiftと共有スキームの有効なテストターゲットが一致しません")


if __name__ == "__main__":
    try:
        names = test_targets(json.load(sys.stdin))
        if len(sys.argv) > 1:
            validate_scheme(names, sys.argv[1])
        print("\n".join(names))
    except (ValueError, KeyError, TypeError, OSError, ET.ParseError, AttributeError) as error:
        print(f"テストターゲットを取得できません: {error}", file=sys.stderr)
        sys.exit(1)
