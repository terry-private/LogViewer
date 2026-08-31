#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(dirname -- "$script_directory")

cd "$repository_directory"

documentation_log=$(mktemp)
documentation_directory=$(mktemp -d)
trap 'rm -f "$documentation_log"; rm -rf "$documentation_directory"' EXIT

for scheme in LogViewerCore LogViewer LogViewerSwiftLog; do
  derived_data="$documentation_directory/$scheme"
  if ! xcodebuild \
      -quiet \
      -scheme "$scheme" \
      -destination "generic/platform=iOS Simulator" \
      -derivedDataPath "$derived_data" \
      docbuild >"$documentation_log" 2>&1; then
    cat "$documentation_log"
    exit 1
  fi

  if awk -v root="$repository_directory" '
      index($0, root) == 1 && /warning:/ { print; found = 1 }
      END { exit found ? 0 : 1 }
    ' "$documentation_log"; then
    echo "DocC warnings were found in LogViewer sources." >&2
    exit 1
  fi

  if [ "$scheme" = "LogViewer" ] &&
      ! find "$derived_data" -name 'LogViewerUI.doccarchive' \
        -type d -print -quit | grep -q .; then
    echo "LogViewer scheme did not build LogViewerUI.doccarchive." >&2
    exit 1
  fi
done
