#!/bin/bash
set -e

ROOT_DIR=.
BUILD_DIR="$ROOT_DIR/build"
DOC_DIR="$ROOT_DIR/aaron"
# Define the output PDF file name
OUTPUT_PDF="$BUILD_DIR/lbc1689_aab.pdf"

mkdir -p "$BUILD_DIR"

# Create a temporary markdown file to concatenate all chapters
TEMP_MD="$BUILD_DIR/lbc1689_aab.md"

# Start with the index
echo "# Index" > $TEMP_MD
cat $DOC_DIR/lbc1689-index.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-index.md -o $BUILD_DIR/lbc1689-index.pdf
printf "\n\n" >> $TEMP_MD

# Add the introduction
echo "# Introduction" >> $TEMP_MD
cat $DOC_DIR/lbc1689-introduction.md >> $TEMP_MD
pandoc $DOC_DIR/lbc1689-introduction.md -o $BUILD_DIR/lbc1689-introduction.pdf
echo "\n\n" >> $TEMP_MD

# Concatenate all chapter files
index=0
for chapter in $DOC_DIR/lbc1689-ch*.md; do
    index=$((index + 1))
    padded_index=$(printf "%02d" $index)
    echo "\newpage" >> $TEMP_MD
    cat "$chapter" >> $TEMP_MD
    echo "\n\n" >> $TEMP_MD
    pandoc $chapter -o "$BUILD_DIR/libc1689-ch$padded_index.pdf"
done

# Add the signatories at the end
echo "# Signatories" >> $TEMP_MD
cat $DOC_DIR/lbc1689-signatories.md >> $TEMP_MD
echo "\n\n" >> $TEMP_MD

# Add the addendums at the last pages
echo "# Addendums" >> $TEMP_MD
cat $DOC_DIR/Addendums.md >> $TEMP_MD

ls -al $DOC_DIR
ls -al $BUILD_DIR

# Convert the combined markdown file to PDF using pandoc
#pandoc $TEMP_MD -o $OUTPUT_PDF

zip $BUILD_dir/lbc1689_aab.zip $BUILD_DIR/*.pdf

echo "PDF generated: $OUTPUT_PDF"
ls -al $BUILD_DIR