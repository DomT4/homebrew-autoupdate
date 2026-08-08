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

  upgrade_line=$(
    /usr/bin/awk '/==> Upgrading [0-9]+ outdated packages?:/ { line = $0 } END { print line }' "${run_log}"
  )

  if [[ -n "${upgrade_line:-}" ]]
  then
    message=${upgrade_line}
  elif /usr/bin/grep -q "Already up-to-date." "${run_log}"
  then
    outdated_packages=$(
      /usr/bin/awk '/^[a-zA-Z0-9][a-zA-Z0-9@._-]*$/ { pkgs[NR]=$0 } !/^[a-zA-Z0-9][a-zA-Z0-9@._-]*$/ { delete pkgs; last_non_pkg=NR } END { for (i=last_non_pkg+1; i<=NR; i++) if (i in pkgs) print pkgs[i] }' "${run_log}"
    )
    outdated_count=$(echo "${outdated_packages}" | /usr/bin/grep -c . 2>/dev/null || true)

    if [[ "${outdated_count}" -gt 0 ]]
    then
      if [[ "${outdated_count}" -eq 1 ]]
      then
        subtitle="1 upgrade available"
      else
        subtitle="${outdated_count} upgrades available"
      fi
      # Truncate the list to fit comfortably in a banner notification.
      message=$(echo "${outdated_packages}" | /usr/bin/awk 'BEGIN { ORS=", " } { print } NR==5 { print "…"; exit }' | /usr/bin/sed 's/, $//')
    else
      message="Homebrew is already up-to-date."
    fi
  else
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
