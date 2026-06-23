#!/bin/bash

set -eu

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source_file="${script_dir}/notifier.swift"
output_app="${script_dir}/brew-autoupdate.app"
version_file="${script_dir}/../VERSION"
identity=${CODESIGN_IDENTITY:-}
version=$(<"${version_file}")
build_dir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/brew-autoupdate-notifier.XXXXXX")
build_app="${build_dir}/brew-autoupdate.app"
backup_app="${build_dir}/previous.app"
executable_name="brew-autoupdate-notifier"

trap '/bin/rm -rf "$build_dir"' EXIT

if [[ -z "${identity}" ]]
then
  echo "Set CODESIGN_IDENTITY to a local Apple code-signing identity." >&2
  exit 1
fi

if [[ ! "${version}" =~ ^[0-9]+(\.[0-9]+){2}$ ]]
then
  echo "Invalid version in ${version_file}: ${version}" >&2
  exit 1
fi

/bin/mkdir -p "${build_app}/Contents/MacOS" "${build_app}/Contents/Resources"
/usr/bin/xcrun --sdk macosx swiftc -swift-version 5 \
  -module-cache-path "${build_dir}/module-cache" \
  -target arm64-apple-macos11.0 "${source_file}" \
  -o "${build_dir}/${executable_name}-arm64"
/usr/bin/xcrun --sdk macosx swiftc -swift-version 5 \
  -module-cache-path "${build_dir}/module-cache" \
  -target x86_64-apple-macos11.0 "${source_file}" \
  -o "${build_dir}/${executable_name}-x86_64"
/usr/bin/lipo -create \
  "${build_dir}/${executable_name}-arm64" \
  "${build_dir}/${executable_name}-x86_64" \
  -output "${build_app}/Contents/MacOS/${executable_name}"

/usr/bin/plutil -create xml1 "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleDevelopmentRegion -string "en" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleExecutable -string "${executable_name}" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleIdentifier -string \
  "com.github.domt4.homebrew-autoupdate.autoupdater" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleInfoDictionaryVersion -string "6.0" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleName -string "brew-autoupdate" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundlePackageType -string "APPL" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleShortVersionString -string "${version}" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleVersion -string "${version}" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleIconFile -string "applet" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert LSMinimumSystemVersion -string "11.0" "${build_app}/Contents/Info.plist"
/usr/bin/plutil -insert LSUIElement -bool true "${build_app}/Contents/Info.plist"

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
