## latex-cv automation

This is my LaTeX CV automation workflow with two output tracks:

1. a full internal version (includes full address/contact details)
2. a redacted public version (safe for website download)

The goal is to keep both variants continuously up to date through git hooks, with minimal manual steps.

## Pipeline overview

1. Pre-commit builds full PDFs and stages them into the commit.
2. Pre-push builds redacted PDFs and publishes them to a public web directory, making them available for download on my website.
3. Full PDFs are also published to a private directory.

## What is included

- [hooks/pre-commit](hooks/pre-commit): builds full PDFs and stages them
- [hooks/pre-push](hooks/pre-push): builds and publishes redacted PDFs
- [scripts/build_full.sh](scripts/build_full.sh): full compile plus private publish
- [scripts/build_redacted.sh](scripts/build_redacted.sh): redacted compile plus public publish
- [scripts/redact_tex.py](scripts/redact_tex.py): switches class token from {resume} to a redacted class identical to resume, but with a redacted \printaddress call

Published output paths used by the deployed scripts:

- redacted/public: /var/www/blog/cv-felix-winterhalter-en.pdf and /var/www/blog/cv-felix-winterhalter-de.pdf
- full/private: /srv/videos/private/cv/cv-felix-winterhalter-en.pdf and /srv/videos/private/cv/cv-felix-winterhalter-de.pdf

## Assumptions

- The CV repository contains at least english.tex and german.tex
- documentclass uses {resume} (See also [resume.cls](resume.cls))
- latexmk is installed
- python3 is installed
- publish directories are writable by the executing user

## Setup steps

From inside a CV repository (for example /home/latex-cv):

cp -r /path/to/utils/latex-cv-hooks/{hooks,scripts} .
chmod +x hooks/pre-commit hooks/pre-push scripts/build_full.sh scripts/build_redacted.sh scripts/redact_tex.py
cp hooks/pre-commit .git/hooks/pre-commit
cp hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push

## Validation commands

scripts/build_full.sh
scripts/build_redacted.sh

Then check:

- full PDFs in /srv/videos/private/cv
- redacted PDFs in /var/www/blog
- build/redacted/hook.log after pushes

## Notes

- The redaction script does not mutate source tex files.
- It writes temporary redacted tex/pdf files under build/redacted.
- Edit the inline class content in scripts/build_redacted.sh to customize the public contact line.
