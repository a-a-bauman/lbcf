#!/bin/bash
set -e

init() {
  ROOT_DIR=.
  BUILD_DIR="$ROOT_DIR/build"
  PDF_DIR="$BUILD_DIR/pdf"
  HTML_DIR="$BUILD_DIR/html"
  DOC_DIR="$ROOT_DIR/aaron"
  OUTPUT_PDF="$BUILD_DIR/lbc1689-aab.pdf"

  mkdir -p "$PDF_DIR"
  mkdir -p "$HTML_DIR"
}

buildHtml() {
  pandoc --standalone $DOC_DIR/OpeningThoughts.md --to html --output $HTML_DIR/OpeningThoughts
  pandoc --standalone $DOC_DIR/lbc1689-toc.md --to html --output $HTML_DIR/lbc1689-toc
  pandoc --standalone $DOC_DIR/lbc1689-introduction.md --to html --output $HTML_DIR/lbc1689-introduction
  # Concatenate all chapter files
  index=0
  for chapter in $DOC_DIR/lbc1689-ch*.md; do
      index=$((index + 1))
      padded_index=$(printf "%02d" $index)
      pandoc --standalone $chapter --to html --output "$HTML_DIR/lbc1689-ch$padded_index"
  done
  pandoc --standalone $DOC_DIR/lbc1689-signatories.md --to html --output $HTML_DIR/lbc1689-signatories
  pandoc --standalone $DOC_DIR/Addendum.md --to html --output $HTML_DIR/lbc1689-Addendum
}

buildPdf() {
  pandoc $DOC_DIR/OpeningThoughts.md $DOC_DIR/lbc1689-toc.md $DOC_DIR/lbc1689-introduction.md $(ls $DOC_DIR/lbc1689-ch*.md) $DOC_DIR/lbc1689-signatories.md $DOC_DIR/Addendum.md --output $OUTPUT_PDF
}

init
buildHtml
buildPdf