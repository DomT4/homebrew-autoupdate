#compdef brew

# Zsh completion script for brew autoupdate command
# To use these completions:
# 1. Copy this file to $fpath/
# 2. Or run `brew completions link` if you have Homebrew's completions enabled

_brew_autoupdate() {
    local -a subcommands
    local -a start_options
    local -a common_options

    subcommands=(
        'start:Start autoupdating'
        'stop:Stop autoupdating, but retain plist and logs'
        'delete:Cancel the autoupdate, delete the plist and logs'
        'status:Print the current status of this tool'
        'version:Output this tool'\''s current version'
    )

    start_options=(
        '--upgrade[Automatically upgrade your installed formulae]'
        '--greedy[Upgrade casks with --greedy (include auto-updating casks)]'
        '--cleanup[Automatically clean Homebrew'\''s cache and logs]'
        '--immediate[Starts the autoupdate command immediately and on system boot]'
        '--sudo[If a cask requires sudo, autoupdate will open a GUI to ask for the password]'
        '--leaves-only[Only upgrade formulae that are not dependencies of another installed formula]'
    )

    common_options=(
        '(-h --help)'{-h,--help}'[Show this message]'
        '(-d --debug)'{-d,--debug}'[Display any debugging information]'
        '(-q --quiet)'{-q,--quiet}'[Make some output more quiet]'
        '(-v --verbose)'{-v,--verbose}'[Make some output more verbose]'
    )

    local curcontext="$curcontext" state line
    _arguments -C \
        ':subcommand:->subcommand' \
        '*::options:->options'

    case $state in
        subcommand)
            _describe -t subcommands 'brew autoupdate subcommand' subcommands
            ;;
        options)
            case $line[1] in
                start)
                    _arguments \
                        '*:interval (seconds)' \
                        $start_options \
                        $common_options
                    ;;
                *)
                    _arguments $common_options
                    ;;
            esac
            ;;
    esac
}

_brew_autoupdate "$@"
