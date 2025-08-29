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
pandoc $DOC_DIR/OpeningThoughts.md -o $PDF_DIR/OpeningThoughts.pdf
pandoc $DOC_DIR/OpeningThoughts.md -o $HTML_DIR/OpeningThoughts.html
printf "\n\n" >> $TEMP_MD

echo "# Index" > $TEMP_MD
cat $DOC_DIR/lbc1689-index.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-index.md -o $PDF_DIR/lbc1689-index.pdf
pandoc $DOC_DIR/lbc1689-index.md -o $HTML_DIR/lbc1689-index.html
printf "\n\n" >> $TEMP_MD

# Add the introduction
echo "# Introduction" >> $TEMP_MD
cat $DOC_DIR/lbc1689-introduction.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-introduction.md -o $PDF_DIR/lbc1689-introduction.pdf
pandoc $DOC_DIR/lbc1689-introduction.md -o $HTML_DIR/lbc1689-introduction.html
echo "\n\n" >> $TEMP_MD

# Concatenate all chapter files
index=0
for chapter in $DOC_DIR/lbc1689-ch*.md; do
    index=$((index + 1))
    padded_index=$(printf "%02d" $index)
    echo "\newpage" >> $TEMP_MD
    cat "$chapter" >> $TEMP_MD
    echo "\n\n" >> $TEMP_MD
    pandoc $chapter -o "$PDF_DIR/lbc1689-ch$padded_index.pdf"
    pandoc $chapter -o "$HTML_DIR/lbc1689-ch$padded_index.html"
done

# Add the signatories at the end
echo "# Signatories" >> $TEMP_MD
cat $DOC_DIR/lbc1689-signatories.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-signatories.md -o $PDF_DIR/lbc1689-signatories.pdf
pandoc $DOC_DIR/lbc1689-signatories.md -o $HTML_DIR/lbc1689-signatories.html
echo "\n\n" >> $TEMP_MD

# Add the addendums at the last pages
echo "# Addendums" >> $TEMP_MD
cat $DOC_DIR/Addendums.md >> $TEMP_MD
pandoc $DOC_DIR/Addendums.md -o $PDF_DIR/lbc1689-Addendums.pdf
pandoc $DOC_DIR/Addendums.md -o $HTML_DIR/lbc1689-Addendums.html

echo "list $DOC_DIR"
ls -alR $DOC_DIR
echo "list $BUILD_DIR"
ls -alR $BUILD_DIR

# Convert the combined markdown file to PDF using pandoc
#pandoc $TEMP_MD -o $OUTPUT_PDF
