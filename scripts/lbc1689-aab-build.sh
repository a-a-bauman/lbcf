#!/bin/bash
set -e

VERSION=$1

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

prepareCommonToBoth() {
  initStagingDir
  DATE="$(date +'%B %d, %Y')"
  echo "Setting Title Page date to ${DATE} and version to ${VERSION}"
  sed -i.bak 's/\$date\$/'"${DATE}"'/g; s/\$version\$/'"${VERSION}/g" "$STAGING_DIR/aab-TitlePage.md"
  rm -f "$STAGING_DIR/aab-TitlePage.md.bak"
}

formatEachChapterWithTocLink() {
  for doc in "${STAGING_DIR}"/*.md; do
    rm -f ${TEMP_MD}
    cat "${doc}" >> ${TEMP_MD}
    echo -e "\n\n[Table of Contents](lbc1689-toc)" >> ${TEMP_MD}
    mv ${TEMP_MD} "${doc}"
  done
}

prepareMarkdownForHtml() {
  prepareCommonToBoth
  formatEachChapterWithTocLink
}

buildHtml() {
  echo "Generating HTML"
  prepareMarkdownForHtml
  pandoc --standalone $STAGING_DIR/aab-TitlePage.md --from markdown+mark --to html --output $HTML_DIR/aab-TitlePage --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/lbc1689-toc.md --from markdown+mark --to html --output $HTML_DIR/lbc1689-toc --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/aab-Testimony.md --from markdown+mark --to html --output $HTML_DIR/aab-Testimony --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/aab-Calling.md --from markdown+mark --to html --output $HTML_DIR/aab-Calling --css $STYLES_DIR/styles.css
  pandoc --standalone $STAGING_DIR/aab-Prologue.md --from markdown+mark --to html --output $HTML_DIR/aab-Prologue --css $STYLES_DIR/styles.css
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

formatEachChapterWithPageBreakExceptTitlePage() {
  for doc in "${STAGING_DIR}"/*.md; do
    if [[ "${doc}" == "aab-TitlePage.md" ]]; then
      continue
    fi
    rm -f ${TEMP_MD}
    echo '\newpage' >> ${TEMP_MD}
    echo -e "\n\n" >> ${TEMP_MD}
    cat "${doc}" >> ${TEMP_MD}
    mv ${TEMP_MD} "${doc}"
  done
}

prepareMarkdownForPdf() {
  prepareCommonToBoth
  formatEachChapterWithPageBreakExceptTitlePage
}

buildPdf() {
  echo "Generating PDF"
  prepareMarkdownForPdf
  pandoc \
      $STAGING_DIR/aab-TitlePage.md \
      $STAGING_DIR/lbc1689-toc.md \
      $STAGING_DIR/aab-Testimony.md \
      $STAGING_DIR/aab-Calling.md \
      $STAGING_DIR/aab-Prologue.md \
      $STAGING_DIR/lbc1689-introduction.md \
      $(ls $STAGING_DIR/lbc1689-ch*.md) \
      $STAGING_DIR/lbc1689-signatories.md \
      $STAGING_DIR/aab-Addendum.md \
      --from markdown+mark \
      --output $GENERATED_PDF \
      --variable date="$(date +'%B %d, %Y')" \
      --variable version="$VERSION" \
      --variable=colorlinks=true \
      --variable=linkcolor=blue \
      --variable=urlcolor=blue \
      --include-in-header=$STYLES_DIR/header.tex
}

init
buildHtml
buildPdf
rm -rf $STAGING_DIR