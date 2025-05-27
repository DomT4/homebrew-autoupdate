#compdef brew

# Zsh completion script for brew autoupdate command
# To use these completions, add the following to your ~/.zshrc:
#
# if [ -f "$(brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.zsh" ]; then
#     source "$(brew --prefix)/Library/Taps/domt4/homebrew-autoupdate/completions/autoupdate.zsh"
# fi

# Register autoupdate as a brew subcommand
_brew_cmds_caching_policy() {
  local -a newer_files
  # rebuild if cache is older than any of the brew executables
  for file in $HOMEBREW_PREFIX/bin/brew $HOMEBREW_REPOSITORY/Library/Homebrew/cmd/*.rb; do
    [[ -f $file && $file -nt $1 ]] && newer_files=($file $newer_files)
  done
  (( $#newer_files )) && return 0
  return 1
}

_brew_commands() {
  local -a commands
  local cache_file="$ZSH_CACHE_DIR/brew_commands"

  if [[ -f "$cache_file" ]]; then
    commands=("${(@f)$(<$cache_file)}")
  else
    commands=($(brew commands --quiet --include-aliases))
    [[ -d "$ZSH_CACHE_DIR" ]] && echo ${(F)commands} >! "$cache_file"
  fi

  # Add autoupdate to the list of commands
  commands+=("autoupdate:An easy, convenient way to automatically update Homebrew")

  _describe -t commands 'brew command' commands
}

# Define completion for the autoupdate subcommand
_brew_autoupdate() {
    local -a subcommands
    local -a start_options
    local -a common_options

    # Only run for the autoupdate command
    if [[ $words[2] != "autoupdate" ]]; then
        return
    fi

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

    # If we're at the autoupdate subcommand level
    if (( CURRENT == 3 )); then
        _describe -t subcommands 'brew autoupdate subcommand' subcommands
        return
    fi

    # If we're at the options level
    if (( CURRENT > 3 )); then
        case $words[3] in
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
    fi
}

# Hook into the brew completion system
(( $+functions[_brew] )) || _brew() {
  local curcontext="$curcontext" state state_descr line
  typeset -A opt_args

  _arguments -C \
    '(-v)-v[verbose]' \
    '1: :->command' \
    '*:: :->argument'

  case "$state" in
    command) _brew_commands ;;
    argument)
      case "$words[1]" in
        autoupdate) _brew_autoupdate ;;
      esac
    ;;
  esac
}

compdef _brew brew
