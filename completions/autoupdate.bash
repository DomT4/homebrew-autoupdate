# Bash completion script for brew autoupdate command
# To use these completions, add the following to your ~/.bash_profile or ~/.bashrc:
#
# if [ -f "$(brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.bash" ]; then
#     source "$(brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.bash"
# fi

# First, register autoupdate as a brew subcommand
_brew_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local brew_commands=$(brew commands --quiet --include-aliases)

    # Add autoupdate to the list of brew commands
    brew_commands="$brew_commands autoupdate"

    COMPREPLY=( $(compgen -W "$brew_commands" -- "$cur") )
    return 0
}

# Then define completion for the autoupdate subcommand
_brew_autoupdate() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local cmd="${COMP_WORDS[1]}"

    # Only run for the autoupdate command
    if [[ "$cmd" != "autoupdate" ]]; then
        return 0
    fi

    local subcommands="start stop delete status version"
    local options="--help --debug --quiet --verbose"
    local start_options="--upgrade --greedy --cleanup --immediate --sudo --leaves-only"

    # If we're completing the autoupdate subcommand
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "${subcommands}" -- "${cur}") )
        return 0
    fi

    # If we're completing options for the start subcommand
    if [[ ${COMP_CWORD} -ge 3 ]]; then
        if [[ "${COMP_WORDS[2]}" == "start" ]]; then
            COMPREPLY=( $(compgen -W "${start_options} ${options}" -- "${cur}") )
            return 0
        else
            # For other subcommands, just show general options
            COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
            return 0
        fi
    fi

    return 0
}

# Register the completion functions
complete -F _brew_complete brew
complete -F _brew_autoupdate brew
