# Completions for brew autoupdate command
# To use these completions, add the following to your ~/.config/fish/config.fish:
#
# if test -f (brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.fish
#     source (brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.fish
# end

# Define the main autoupdate command completions
complete -c brew -f -n "__fish_brew_command autoupdate" -a "start" -d "Start autoupdating"
complete -c brew -f -n "__fish_brew_command autoupdate" -a "stop" -d "Stop autoupdating, but retain plist and logs"
complete -c brew -f -n "__fish_brew_command autoupdate" -a "delete" -d "Cancel the autoupdate, delete the plist and logs"
complete -c brew -f -n "__fish_brew_command autoupdate" -a "status" -d "Print the current status of this tool"
complete -c brew -f -n "__fish_brew_command autoupdate" -a "version" -d "Output this tool's current version"

# Define options for the start subcommand
complete -c brew -f -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "upgrade" -d "Automatically upgrade your installed formulae"
complete -c brew -f -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "greedy" -d "Upgrade casks with --greedy (include auto-updating casks)"
complete -c brew -f -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "cleanup" -d "Automatically clean Homebrew's cache and logs"
complete -c brew -f -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "immediate" -d "Starts the autoupdate command immediately and on system boot"
complete -c brew -f -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "sudo" -d "If a cask requires sudo, autoupdate will open a GUI to ask for the password"
complete -c brew -f -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "leaves-only" -d "Only upgrade formulae that are not dependencies of another installed formula"

# Define common options for all subcommands
complete -c brew -f -n "__fish_brew_command autoupdate" -s "h" -l "help" -d "Show this message"
complete -c brew -f -n "__fish_brew_command autoupdate" -s "d" -l "debug" -d "Display any debugging information"
complete -c brew -f -n "__fish_brew_command autoupdate" -s "q" -l "quiet" -d "Make some output more quiet"
complete -c brew -f -n "__fish_brew_command autoupdate" -s "v" -l "verbose" -d "Make some output more verbose"
