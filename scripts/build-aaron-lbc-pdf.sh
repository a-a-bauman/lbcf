#!/bin/bash
set -e

init() {
  ROOT_DIR=.
  BUILD_DIR="$ROOT_DIR/build"
  STAGING_DIR="$BUILD_DIR/stagingHtml"
  PDF_DIR="$BUILD_DIR/pdf"
  HTML_DIR="$BUILD_DIR/html"
  DOC_DIR="$ROOT_DIR/aaron"
  GENERATED_PDF="$BUILD_DIR/lbc1689-aab.pdf"
  TEMP_MD="$BUILD_DIR/temp.md"

  mkdir -p ${STAGING_DIR}
  mkdir -p ${PDF_DIR}
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
  pandoc --standalone $STAGING_DIR/aab-TitlePage.md --to html --output $HTML_DIR/TitlePage
  pandoc --standalone $STAGING_DIR/aab-OpeningThoughts.md --to html --output $HTML_DIR/OpeningThoughts
  pandoc --standalone $STAGING_DIR/lbc1689-toc.md --to html --output $HTML_DIR/lbc1689-toc
  pandoc --standalone $STAGING_DIR/lbc1689-introduction.md --to html --output $HTML_DIR/lbc1689-introduction
  # Concatenate all chapter files
  index=0
  for chapter in "$STAGING_DIR"/lbc1689-ch*.md; do
      index=$((index + 1))
      padded_index=$(printf "%02d" $index)
      pandoc --standalone "${chapter}" --to html --output "$HTML_DIR/lbc1689-ch$padded_index"
  done
  pandoc --standalone $STAGING_DIR/lbc1689-signatories.md --to html --output $HTML_DIR/lbc1689-signatories
  pandoc --standalone $STAGING_DIR/aab-Addendum.md --to html --output $HTML_DIR/Addendum
}

prepareMarkdownForPdf() {
  initStagingDir
  for doc in "${STAGING_DIR}"/*.md; do
    rm -f ${TEMP_MD}
    echo -e "\newpage\n\n" >> ${TEMP_MD}
    cat "${doc}" >> ${TEMP_MD}
    mv ${TEMP_MD} "${doc}"
  done
  # Do not want to begin the Title Page with a new page
  cp $DOC_DIR/aab-TitlePage.md $STAGING_DIR
}

buildPdf() {
  prepareMarkdownForPdf
  pandoc $DOC_DIR/aab-TitlePage.md $DOC_DIR/aab-OpeningThoughts.md $DOC_DIR/lbc1689-toc.md $DOC_DIR/lbc1689-introduction.md "$(ls $DOC_DIR/lbc1689-ch*.md)" $DOC_DIR/lbc1689-signatories.md $DOC_DIR/aab-Addendum.md --output $GENERATED_PDF
}

init
buildHtml
buildPdf