#!/bin/sh
printf '\033c\033]0;%s\a' First_3D
base_path="$(dirname "$(realpath "$0")")"
"$base_path/First_3D.x86_64" "$@"
