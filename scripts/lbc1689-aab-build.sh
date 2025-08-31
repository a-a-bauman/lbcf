#!/bin/bash
set -e

init() {
  ROOT_DIR=.
  BUILD_DIR="$ROOT_DIR/build"
  STAGING_DIR="$BUILD_DIR/stagingHtml"
  HTML_DIR="$BUILD_DIR/html"
  DOC_DIR="$ROOT_DIR/aaron"
  STYLES_DIR="$DOC_DIR/styles"
  GENERATED_PDF="$BUILD_DIR/lbc1689-aab.pdf"
  TEMP_MD="$BUILD_DIR/temp.md"

  mkdir -p ${STAGING_DIR}
  mkdir -p ${HTML_DIR}
}

initStagingDir() {
  rm -f ${STAGING_DIR}/*.md
  cp ${DOC_DIR}/*.md ${STAGING_DIR}
}

prepareMarkdownForHtml() {
  initStagingDir
  for doc in "${STAGING_DIR}"/*.md; do
    rm -f ${TEMP_MD}
    cat "${doc}" >> ${TEMP_MD}
    echo -e "\n\n[Table of Contents](lbc1689-toc)" >> ${TEMP_MD}
    mv ${TEMP_MD} "${doc}"
  done
}

buildHtml() {
  prepareMarkdownForHtml
  pandoc --standalone $STAGING_DIR/aab-TitlePage.md --from markdown+mark --to html --output $HTML_DIR/aab-TitlePage --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/aab-OpeningThoughts.md --from markdown+mark --to html --output $HTML_DIR/aab-OpeningThoughts --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/lbc1689-toc.md --from markdown+mark --to html --output $HTML_DIR/lbc1689-toc --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/lbc1689-introduction.md --from markdown+mark --to html --output $HTML_DIR/lbc1689-introduction --css $STYLES_DIR/styles.css
  # Concatenate all chapter files
  index=0
  for chapter in "$STAGING_DIR"/lbc1689-ch*.md; do
      index=$((index + 1))
      padded_index=$(printf "%02d" $index)
      pandoc --standalone "${chapter}" --from markdown+mark --to html --output "$HTML_DIR/lbc1689-ch$padded_index" --css $STYLES_DIR/styles.css
  done
  pandoc --standalone $STAGING_DIR/lbc1689-signatories.md --from markdown+mark --to html --output $HTML_DIR/lbc1689-signatories --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/aab-Addendum.md --from markdown+mark --to html --output $HTML_DIR/aab-Addendum --css $STYLES_DIR/styles.css
}

prepareMarkdownForPdf() {
  initStagingDir
  for doc in "${STAGING_DIR}"/*.md; do
    rm -f ${TEMP_MD}
    echo '\newpage' >> ${TEMP_MD}
    echo -e "\n\n" >> ${TEMP_MD}
    cat "${doc}" >> ${TEMP_MD}
    mv ${TEMP_MD} "${doc}"
  done
  # Do not want to begin the Title Page with a new page
  cp $DOC_DIR/aab-TitlePage.md $STAGING_DIR
}

buildPdf() {
  prepareMarkdownForPdf
  pandoc $STAGING_DIR/aab-TitlePage.md $STAGING_DIR/lbc1689-toc.md $STAGING_DIR/aab-OpeningThoughts.md $STAGING_DIR/lbc1689-introduction.md $(ls $STAGING_DIR/lbc1689-ch*.md) $STAGING_DIR/lbc1689-signatories.md $STAGING_DIR/aab-Addendum.md --from markdown+mark --output $GENERATED_PDF --css $STYLES_DIR/styles.css
}

init
buildHtml
buildPdf
rm -rf $STAGING_DIR