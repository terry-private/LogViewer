#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(dirname -- "$script_directory")
test_destination=${LOGVIEWER_TEST_DESTINATION:-"platform=iOS Simulator,name=iPhone 16,OS=18.0"}

cd "$repository_directory"

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
