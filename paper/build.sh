#! /bin/bash

ex() {
  echo >&2 "\$ $@"
  "$@"
}

cd "$(dirname "$0")"
ex pandoc \
  --pdf-engine=xelatex \
  --template=template.tex \
  --metadata-file=./meta.yaml --metadata date="DRAFT GENERATED `date +%F`" \
  -C --bibliography=bib.bib --csl=../vendor/citation-styles/springer-lecture-notes-in-computer-science.csl \
  decryption-despite-errors.md -o decryption-despite-errors.pdf
