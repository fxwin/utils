#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="$root_dir/build/redacted"
publish_dir="/var/www/blog"

mkdir -p "$out_dir"
mkdir -p "$publish_dir"

cat > "$out_dir/resume_redacted_en.cls" <<'EOF'
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{resume_redacted_en}[2026/03/01 Redacted resume class]
\LoadClass{resume}
\renewcommand{\document}{
  \ori@document
  \printname
  \printaddress{detailed contact info upon request: work@fxwin.net $\cdot$ https://fxwin.net}
}
EOF

cat > "$out_dir/resume_redacted_de.cls" <<'EOF'
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{resume_redacted_de}[2026/03/01 Redacted resume class]
\LoadClass{resume}
\renewcommand{\document}{
  \ori@document
  \printname
  \printaddress{detaillierte kontaktinformationen auf anfrage: work@fxwin.net $\cdot$ https://fxwin.net}
}
EOF

for lang in english german; do
  src="$root_dir/${lang}.tex"
  redacted_tex="$out_dir/${lang}_redacted.tex"

  "$root_dir/scripts/redact_tex.py" "$src" "$redacted_tex"

  if [[ "$lang" == "english" ]]; then
    code="en"
  else
    code="de"
  fi

  TEXINPUTS="$out_dir:$root_dir:" latexmk -pdf -interaction=nonstopmode -output-directory="$out_dir" "$redacted_tex"
  cp "$out_dir/${lang}_redacted.pdf" "$publish_dir/cv-felix-winterhalter-${code}.pdf"
done
