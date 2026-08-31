#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(dirname -- "$script_directory")
project_path="$repository_directory/Examples/LogViewerSample/LogViewerSample.xcodeproj"
test_destination=${LOGVIEWER_SAMPLE_DESTINATION:-}

cd "$repository_directory"

xcodebuild \
  -quiet \
  -project "$project_path" \
  -scheme LogViewerSample \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [ -z "$test_destination" ]; then
  simulator_id=$(
    xcodebuild \
      -project "$project_path" \
      -scheme LogViewerSample \
      -showdestinations 2>/dev/null |
      awk '
        /Ineligible destinations|Destinations incompatible/ { exit }
        /platform:iOS Simulator, arch:.*name:iPad/ {
          candidate = $0
          sub(/^.*id:/, "", candidate)
          sub(/,.*/, "", candidate)
          gsub(/[[:space:]]/, "", candidate)
          print candidate
          exit
        }
      '
  )

  if [ -z "$simulator_id" ]; then
    echo "No compatible iPad Simulator was found for LogViewerSample." >&2
    echo "Set LOGVIEWER_SAMPLE_DESTINATION to an installed destination." >&2
    exit 1
  fi

  test_destination="platform=iOS Simulator,id=$simulator_id"
fi

xcodebuild \
  -quiet \
  -project "$project_path" \
  -scheme LogViewerSample \
  -destination "$test_destination" \
  build-for-testing

tests='testWindowPresentationSearchAndKeyRestorationFromSheet
testWindowAppearsOverFullScreenAndAlert
testFilteredCopyContainsOnlyProtectedResult
testTextAndJSONShareOpenOnlyAfterExplicitAction
testJapaneseMaximumTextKeepsImportantActionsReachable
testEnglishMaximumTextKeepsImportantActionsReachable
testSecondarySceneCanBeOpened'

for test_name in $tests; do
  xcodebuild \
    -quiet \
    -project "$project_path" \
    -scheme LogViewerSample \
    -destination "$test_destination" \
    -only-testing:"LogViewerSampleUITests/LogViewerSampleUITests/$test_name" \
    test-without-building
done
