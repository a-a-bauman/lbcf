#!/bin/bash

ROOT_DIR=../..
BUILD_DIR=build
DOC_DIR=aaron
# Define the output PDF file name
OUTPUT_PDF="$ROOT_DIR/$BUILD_DIR/lbc1689_aab.pdf"

mkdir -p "$ROOT_DIR/$BUILD_DIR"

# Create a temporary markdown file to concatenate all chapters
TEMP_MD="$ROOT_DIR/$BUILD_DIR/lbc1689_aab.md"

# Start with the index
echo "# Index" > $TEMP_MD
cat $DOC_DIR/lbc1689-index.md >> $TEMP_MD
printf "\n\n" >> $TEMP_MD

# Add the introduction
echo "# Introduction" >> $TEMP_MD
cat $DOC_DIR/lbc1689-introduction.md >> $TEMP_MD
echo "\n\n" >> $TEMP_MD

# Concatenate all chapter files
for chapter in $DOC_DIR/lbc1689-ch*.md; do
    echo "\newpage" >> $TEMP_MD
    cat "$chapter" >> $TEMP_MD
    echo "\n\n" >> $TEMP_MD
done

# Add the signatories at the end
echo "# Signatories" >> $TEMP_MD
cat $DOC_DIR/lbc1689-signatories.md >> $TEMP_MD
echo "\n\n" >> $TEMP_MD

# Add the addendums at the last pages
echo "# Addendums" >> $TEMP_MD
cat $DOC_DIR/Addendums.md >> $TEMP_MD

# Convert the combined markdown file to PDF using pandoc
pandoc $TEMP_MD -o $OUTPUT_PDF

# Clean up the temporary markdown file
rm $TEMP_MD

echo "PDF generated: $OUTPUT_PDF"