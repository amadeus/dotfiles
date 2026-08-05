# Personal Dotfiles

My personal dotfiles that are managed via [chezmoi](https://www.chezmoi.io) and
the [1Password CLI](https://developer.1password.com/docs/cli/).  See the
respective pages for setup.

## Setup

With chezmoi and the 1Password CLI installed and signed in, initialize and
apply everything in one shot:

```sh
chezmoi init --apply amadeus
```

This clones the repo to `~/.local/share/chezmoi` and applies the dotfiles,
resolving secrets from 1Password along the way.

To preview what would change without touching anything:

```sh
chezmoi init amadeus
chezmoi diff
```
