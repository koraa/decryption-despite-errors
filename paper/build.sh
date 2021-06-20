#! /bin/bash

ex() {
  echo >&2 "\$ $@"
  "$@"
}

cd "$(dirname "$0")"
ex pandoc \
  --pdf-engine=xelatex \
  --metadata-file=./meta.yaml --metadata date="DRAFT GENERATED `date +%F`" \
  decryption-despite-errors.md -o decryption-despite-errors.pdf
