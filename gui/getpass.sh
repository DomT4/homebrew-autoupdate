#!/bin/bash
PW="$(printf "%s\n" "SETOK OK" "SETCANCEL Cancel" "SETDESC homebrew-autoupdate needs your admin password to complete the task" "SETPROMPT Enter Password:$
echo "$PW"