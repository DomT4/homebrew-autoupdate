#!/bin/bash

set -eu

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source_file="${script_dir}/notifier.applescript"
output_app="${script_dir}/brew-autoupdate.app"
identity=${CODESIGN_IDENTITY:-}
version=${NOTIFIER_VERSION:-3.4.1}
build_dir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/brew-autoupdate-notifier.XXXXXX")
build_app="${build_dir}/brew-autoupdate.app"
backup_app="${build_dir}/previous.app"

trap '/bin/rm -rf "$build_dir"' EXIT

if [[ -z "${identity}" ]]
then
  echo "Set CODESIGN_IDENTITY to a local Apple code-signing identity." >&2
  exit 1
fi

/usr/bin/osacompile -o "${build_app}" "${source_file}"
/usr/bin/plutil -replace CFBundleIdentifier -string \
  "com.github.domt4.homebrew-autoupdate.autoupdater" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "brew-autoupdate" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleShortVersionString -string "${version}" "${build_app}/Contents/Info.plist"

unused_plist_keys=(
  LSRequiresCarbon
  NSAppleEventsUsageDescription
  NSAppleMusicUsageDescription
  NSCalendarsUsageDescription
  NSCameraUsageDescription
  NSContactsUsageDescription
  NSHomeKitUsageDescription
  NSMicrophoneUsageDescription
  NSPhotoLibraryUsageDescription
  NSRemindersUsageDescription
  NSSiriUsageDescription
  NSSystemAdministrationUsageDescription
  WindowState
)
for key in "${unused_plist_keys[@]}"
do
  /usr/libexec/PlistBuddy -c "Delete :${key}" "${build_app}/Contents/Info.plist" 2>/dev/null || true
done

/bin/cp "${script_dir}/applet.icns" "${build_app}/Contents/Resources/applet.icns"
/usr/bin/codesign --force --deep --options runtime --sign "${identity}" "${build_app}"
/usr/bin/codesign --verify --deep --strict --verbose=2 "${build_app}"

if [[ -d "${output_app}" ]]
then
  /bin/mv "${output_app}" "${backup_app}"
fi
/bin/mv "${build_app}" "${output_app}"

if ! /usr/bin/codesign --force --deep --options runtime --sign "${identity}" "${output_app}" ||
   ! /usr/bin/codesign --verify --deep --strict --verbose=2 "${output_app}"
then
  /bin/rm -rf "${output_app}"
  if [[ -d "${backup_app}" ]]
  then
    /bin/mv "${backup_app}" "${output_app}"
  fi
  echo "Signing failed; restored the previous notifier app." >&2
  exit 1
fi

echo "Built, verified, and installed ${output_app}"
