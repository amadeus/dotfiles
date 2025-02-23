if test (uname -m) = "arm64"
    set -Ux HOMEBREW_PREFIX /opt/homebrew
else
    set -Ux HOMEBREW_PREFIX /usr/local
end

set -Ux HOMEBREW_BIN $HOMEBREW_PREFIX/bin
set -Ux HOMEBREW_SBIN $HOMEBREW_PREFIX/sbin

fish_add_path $HOMEBREW_BIN
fish_add_path $HOMEBREW_SBIN

if test -e $HOMEBREW_BIN/brew
    eval ($HOMEBREW_BIN/brew shellenv)
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# proto
set -gx PROTO_HOME "$HOME/.proto";
set -gx PATH "$PROTO_HOME/shims" "$PROTO_HOME/bin" $PATH;

if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting 'sup bisch'
    set -gx EDITOR nvim
end
