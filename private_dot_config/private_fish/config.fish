if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting 'sup bisch'
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
