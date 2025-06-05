# Completions for brew autoupdate command
# To use these completions, add the following to your ~/.config/fish/config.fish:
#
# if test -f (brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.fish
#     source (brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.fish
# end

# register main command - this is the first step
# use the official brew.fish actual use way
function __fish_brew_needs_command
    not __fish_brew_command
end

# add autoupdate command to brew command list
complete -f -c brew -n "__fish_brew_needs_command" -a autoupdate -d "An easy, convenient way to automatically update Homebrew"

# define subcommands
complete -f -c brew -n "__fish_brew_command autoupdate" -a "start" -d "Start autoupdating"
complete -f -c brew -n "__fish_brew_command autoupdate" -a "stop" -d "Stop autoupdating, but retain plist and logs"
complete -f -c brew -n "__fish_brew_command autoupdate" -a "delete" -d "Cancel the autoupdate, delete the plist and logs"
complete -f -c brew -n "__fish_brew_command autoupdate" -a "status" -d "Print the current status of this tool"
complete -f -c brew -n "__fish_brew_command autoupdate" -a "version" -d "Output this tool's current version"

# define start subcommand options
complete -f -c brew -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "upgrade" -d "Automatically upgrade your installed formulae"
complete -f -c brew -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "greedy" -d "Upgrade casks with --greedy (include auto-updating casks)"
complete -f -c brew -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "cleanup" -d "Automatically clean Homebrew's cache and logs"
complete -f -c brew -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "immediate" -d "Starts the autoupdate command immediately and on system boot"
complete -f -c brew -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "sudo" -d "If a cask requires sudo, autoupdate will open a GUI to ask for the password"
complete -f -c brew -n "__fish_brew_command autoupdate; and __fish_brew_args | string match -q 'start'" -l "leaves-only" -d "Only upgrade formulae that are not dependencies of another installed formula"

# define common options
complete -f -c brew -n "__fish_brew_command autoupdate" -s "h" -l "help" -d "Show this message"
complete -f -c brew -n "__fish_brew_command autoupdate" -s "d" -l "debug" -d "Display any debugging information"
complete -f -c brew -n "__fish_brew_command autoupdate" -s "q" -l "quiet" -d "Make some output more quiet"
complete -f -c brew -n "__fish_brew_command autoupdate" -s "v" -l "verbose" -d "Make some output more verbose"
