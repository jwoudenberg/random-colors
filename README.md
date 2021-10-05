# `random-colors`

Uses the amazing [colormind.io] to generate random color schemes for your terminal. Give every branch of every git project on your machine a unique look!

## Supported terminals and shells

I tested `random-colors` with these terminals:

- iTerm
- Alacritty
- Kitty

It probably works with other xterm-compatible terminals. If you've had success using `random-colors` on a different terminal, please let me know in a Github issue!

`random-colors` support these shells:

- bash
- fish

PR's adding support for more shells are most welcome!

## Installation

The easiest way to install this is using Nix:

```
nix-env -if https://github.com/jwoudenberg/random-colors/archive/master.tar.gz
```

`random-colors` needs to hook into your shell so it knows when you switch directories.

For bash:

```
echo 'eval "$(random-colors --hook=bash)"' >> ~/.bashrc
```

For fish:

```
echo `random-colors --hook=fish | source` >> ~/.config/fish/config.fish
```

## Usage

After the installation `random-colors` should work automatically. Try `cd`-ing into a git directory or changing branches. If the color scheme generated is not to your liking, you can generate a different one using

```
random-colors --refresh
```

`random-colors` remembers which scheme belongs to a particular project and branch and will restore it once you return to the project and branch.

[colormind.io]: http://colormind.io/
