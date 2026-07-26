#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(dirname -- "$script_directory")
test_destination=${LOGVIEWER_TEST_DESTINATION:-}

cd "$repository_directory"

if [ -z "$test_destination" ]; then
  simulator_id=$(
    xcodebuild -scheme LogViewer -showdestinations 2>/dev/null |
      awk '
        /Ineligible destinations|Destinations incompatible/ { exit }
        /platform:iOS Simulator, arch:/ {
          candidate = $0
          sub(/^.*id:/, "", candidate)
          sub(/,.*/, "", candidate)
          gsub(/[[:space:]]/, "", candidate)
        }
        END {
          print candidate
        }
      '
  )

  if [ -z "$simulator_id" ]; then
    echo "No compatible iOS Simulator was found for the LogViewer scheme." >&2
    echo "Set LOGVIEWER_TEST_DESTINATION to an installed destination." >&2
    exit 1
  fi

  test_destination="platform=iOS Simulator,id=$simulator_id"
fi

swift package dump-package >/dev/null

xcodebuild \
  -quiet \
  -scheme LogViewer \
  -destination "generic/platform=iOS Simulator" \
  IPHONEOS_DEPLOYMENT_TARGET=18.0 \
  build

xcodebuild \
  -quiet \
  -scheme LogViewer \
  -destination "$test_destination" \
  test
