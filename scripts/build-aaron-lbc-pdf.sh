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

# Create a temporary markdown file to concatenate all chapters
TEMP_MD="$BUILD_DIR/lbc1689_aab.md"

cat $DOC_DIR/OpeningThoughts.md >> $TEMP_MD
pandoc $DOC_DIR/OpeningThoughts.md --output $PDF_DIR/OpeningThoughts.pdf
pandoc $DOC_DIR/OpeningThoughts.md --to html --output $HTML_DIR/OpeningThoughts
printf "\n\n" >> $TEMP_MD

cat $DOC_DIR/lbc1689-index.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-index.md --output $PDF_DIR/lbc1689-index.pdf
pandoc $DOC_DIR/lbc1689-index.md --to html --output $HTML_DIR/lbc1689-index
printf "\n\n" >> $TEMP_MD

# Add the introduction
echo "# Introduction" >> $TEMP_MD
cat $DOC_DIR/lbc1689-introduction.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-introduction.md --output $PDF_DIR/lbc1689-introduction.pdf
pandoc $DOC_DIR/lbc1689-introduction.md --to html --output $HTML_DIR/lbc1689-introduction
echo "\n\n" >> $TEMP_MD

# Concatenate all chapter files
index=0
for chapter in $DOC_DIR/lbc1689-ch*.md; do
    index=$((index + 1))
    padded_index=$(printf "%02d" $index)
    echo "\newpage" >> $TEMP_MD
    cat "$chapter" >> $TEMP_MD
    echo "\n\n" >> $TEMP_MD
    pandoc $chapter --output "$PDF_DIR/lbc1689-ch$padded_index.pdf"
    pandoc $chapter --to html --output "$HTML_DIR/lbc1689-ch$padded_index"
done

echo "# Signatories" >> $TEMP_MD
cat $DOC_DIR/lbc1689-signatories.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-signatories.md --output $PDF_DIR/lbc1689-signatories.pdf
pandoc $DOC_DIR/lbc1689-signatories.md --to html --output $HTML_DIR/lbc1689-signatories
echo "\n\n" >> $TEMP_MD

echo "# Addendums" >> $TEMP_MD
cat $DOC_DIR/Addendum.md >> $TEMP_MD
pandoc $DOC_DIR/Addendum.md --output $PDF_DIR/lbc1689-Addendums.pdf
pandoc $DOC_DIR/Addendum.md --to html --output $HTML_DIR/lbc1689-Addendums

echo "list $DOC_DIR"
ls -alR $DOC_DIR
echo "list $BUILD_DIR"
ls -alR $BUILD_DIR

# Convert the combined markdown file to PDF using pandoc
#pandoc $TEMP_MD --output $OUTPUT_PDF
