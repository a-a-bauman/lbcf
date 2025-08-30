#!/bin/bash
set -e

ROOT_DIR=.
BUILD_DIR="$ROOT_DIR/build"
PDF_DIR="$BUILD_DIR/pdf"
HTML_DIR="$BUILD_DIR/html"
DOC_DIR="$ROOT_DIR/aaron"
# Define the output PDF file name
OUTPUT_PDF="$BUILD_DIR/lbc1689_aab.pdf"

mkdir -p "$PDF_DIR"
mkdir -p "$HTML_DIR"

pandoc $DOC_DIR/OpeningThoughts.md --output $PDF_DIR/OpeningThoughts.pdf
pandoc --standalone $DOC_DIR/OpeningThoughts.md --to html --output $HTML_DIR/OpeningThoughts

pandoc $DOC_DIR/lbc1689-index.md --output $PDF_DIR/lbc1689-index.pdf
pandoc --standalone $DOC_DIR/lbc1689-index.md --to html --output $HTML_DIR/lbc1689-index

# Add the introduction
pandoc $DOC_DIR/lbc1689-introduction.md --output $PDF_DIR/lbc1689-introduction.pdf
pandoc --standalone $DOC_DIR/lbc1689-introduction.md --to html --output $HTML_DIR/lbc1689-introduction

# Concatenate all chapter files
index=0
for chapter in $DOC_DIR/lbc1689-ch*.md; do
    index=$((index + 1))
    padded_index=$(printf "%02d" $index)
    pandoc $chapter --output "$PDF_DIR/lbc1689-ch$padded_index.pdf"
    pandoc --standalone $chapter --to html --output "$HTML_DIR/lbc1689-ch$padded_index"
done

pandoc $DOC_DIR/lbc1689-signatories.md --output $PDF_DIR/lbc1689-signatories.pdf
pandoc --standalone $DOC_DIR/lbc1689-signatories.md --to html --output $HTML_DIR/lbc1689-signatories

pandoc $DOC_DIR/Addendum.md --output $PDF_DIR/lbc1689-Addendum.pdf
pandoc --standalone $DOC_DIR/Addendum.md --to html --output $HTML_DIR/lbc1689-Addendum

# Build one combined PDF files
pandoc $DOC_DIR/OpeningThoughts.md $DOC_DIR/lbc1689-index.md $DOC_DIR/lbc1689-introduction.md $(ls $DOC_DIR/lbc1689-ch*.md) $DOC_DIR/lbc1689-signatories.md $DOC_DIR/Addendum.md --output $PDF_DIR/lbc1689-aab.pdf

echo "list $DOC_DIR"
ls -alR $DOC_DIR
echo "list $BUILD_DIR"
ls -alR $BUILD_DIR
