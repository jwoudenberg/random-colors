#!/usr/bin/env bash

cd() {
  builtin cd "$@" || return
  (random_colors_bin_path &)
}
