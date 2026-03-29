#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
publish_dir="/srv/videos/private/cv"
cd "$root_dir"

mkdir -p "$publish_dir"

latexmk -pdf -interaction=nonstopmode english.tex
latexmk -pdf -interaction=nonstopmode german.tex

cp "$root_dir/english.pdf" "$publish_dir/cv-felix-winterhalter-en.pdf"
cp "$root_dir/german.pdf" "$publish_dir/cv-felix-winterhalter-de.pdf"
