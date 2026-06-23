#!/bin/bash

set -u

status=${1:?missing exit status}
run_log=${2:?missing run log}
mode=${3:-always}
notifier_app=${4:-}

if [[ "${mode}" = "never" ]] || { [[ "${mode}" = "error" ]] && [[ "${status}" -eq 0 ]]; }
then
  exit 0
fi

if [[ "${status}" -eq 0 ]]
then
  title="Homebrew autoupdate completed"
  subtitle="brew-autoupdate"

  if /usr/bin/grep -q "Already up-to-date." "${run_log}"
  then
    message="Homebrew is already up-to-date."
  else
    upgrade_line=$(
      /usr/bin/awk '/==> Upgrading [0-9]+ outdated packages?:/ { line = $0 } END { print line }' "${run_log}"
    )
  fi

  if [[ -n "${upgrade_line:-}" ]]
  then
    message=${upgrade_line}
  elif [[ -z "${message:-}" ]]
  then
    message="Homebrew was updated successfully."
  fi
else
  title="Homebrew autoupdate failed"
  subtitle="Exit status ${status}"
  message=$(
    /usr/bin/awk 'NF { lines[++count] = $0 } END {
      start = count > 5 ? count - 4 : 1
      for (i = start; i <= count; i++) print lines[i]
    }' "${run_log}"
  )
  message=${message:-"See the autoupdate log for details."}
fi

if [[ "${AUTUPDATE_NOTIFY_PRINT:-0}" = "1" ]]
then
  /usr/bin/printf "%s\n%s\n%s\n" "${title}" "${subtitle}" "${message}"
  exit 0
fi

notifier_executable="${notifier_app}/Contents/MacOS/brew-autoupdate-notifier"
if [[ -z "${notifier_app}" ]] || [[ ! -x "${notifier_executable}" ]]
then
  /usr/bin/printf "Warning: notifier app not found: %s\n" "${notifier_app}" >&2
  exit 0
fi

if ! "${notifier_executable}" "${title}" "${subtitle}" "${message}"
then
  /usr/bin/printf "Warning: notifier failed to display the update result.\n" >&2
fi
