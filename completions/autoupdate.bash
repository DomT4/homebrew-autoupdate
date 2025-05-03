# Bash completion script for brew autoupdate command
# To use these completions, add the following to your ~/.bash_profile or ~/.bashrc:
#
# if [ -f "$(brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.bash" ]; then
#     source "$(brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.bash"
# fi

_brew_autoupdate() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local subcommands="start stop delete status version"
    local options="--help --debug --quiet --verbose"
    local start_options="--upgrade --greedy --cleanup --immediate --sudo --leaves-only"

    # If we're completing the brew command itself
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${subcommands}" -- "${cur}") )
        return 0
    fi

    # If we're completing a subcommand
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        case "${prev}" in
            autoupdate)
                COMPREPLY=( $(compgen -W "${subcommands}" -- "${cur}") )
                return 0
                ;;
        esac
    fi

    # If we're completing options for the start subcommand
    if [[ ${COMP_CWORD} -ge 2 ]]; then
        for i in "${!COMP_WORDS[@]}"; do
            if [[ "${COMP_WORDS[i]}" == "start" ]]; then
                COMPREPLY=( $(compgen -W "${start_options} ${options}" -- "${cur}") )
                return 0
            fi
        done
    fi

    # Default to general options
    COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
    return 0
}

complete -F _brew_autoupdate brew
