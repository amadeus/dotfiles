# Mac Studio SMC Light Helper

This Hammerspoon config uses `smc-lite` to control the Mac Studio front status light:

- `LSSB 0201`: pulse/breathe
- `LSSB 0101`: steady on
- `LSOO 00`: hard off
- `LSOO 01`: hard on

The SMC writes require root. Hammerspoon runs them with `sudo -n`, so it will fail quickly without prompting if sudoers is not configured.

## Create the sudoers file

Open a dedicated sudoers file with Neovim:

```fish
env EDITOR=nvim sudo visudo -f /etc/sudoers.d/macstudio-led
```

Use this as the full contents:

```sudoers
amadeus ALL=(root) NOPASSWD: /Users/amadeus/.hammerspoon/smc-lite write LSOO 00, /Users/amadeus/.hammerspoon/smc-lite write LSOO 01, /Users/amadeus/.hammerspoon/smc-lite write LSSB 0201, /Users/amadeus/.hammerspoon/smc-lite write LSSB 0101
```

Save and quit in Neovim:

```vim
:wq
```

## Test the sudoers rule

These should run without a password prompt:

```fish
sudo -n /Users/amadeus/.hammerspoon/smc-lite write LSSB 0201
sudo -n /Users/amadeus/.hammerspoon/smc-lite write LSSB 0101
```

## Reload Hammerspoon

```fish
open -g "hammerspoon://reload"
```
