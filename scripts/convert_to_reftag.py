#!/usr/bin/env python3
"""
convert_to_reftag.py

Usage:
  python scripts/convert_to_reftag.py input.md -o output.md
  python scripts/convert_to_reftag.py input.md --inplace

  Finds scripture citations that are NOT inside square-brackets and 
  replaces them with markdown links to `https://ref.ly/...`. It is
  conservative by design to avoid changing link text and bracketed content.

Key behavior
------------
- The script only converts references that match a chapter:verse pattern
  (e.g. `3:15`).
- It skips any text inside square brackets (`[...]`) so existing bracketed
  citations or link labels are preserved.
- When building the ref.ly path it replaces the chapter:verse colon `:` with
  a dot (`.`) (to match the project's existing links), and percent-encodes
  the rest of the text.
- Verse ranges with hyphens are normalized to an en-dash (U+2013) before
  encoding. That results in the percent-encoded sequence `%E2%80%93` in the
  final URL (this matches the encoding used in the repo).
- The script always prints the converted file to stdout so you can pipe or
  redirect the output. It also supports writing back to the input file
  (`--inplace`) or writing to a separate output file (`-o output.md`).

Examples
--------
- Print converted content to stdout:

  python3 scripts/convert_to_reftag.py path/to/file.md

- Write the converted content to a new file and still print to stdout:

  python3 scripts/convert_to_reftag.py path/to/file.md -o path/to/out.md

- Overwrite the original file (in-place) and print to stdout:

  python3 scripts/convert_to_reftag.py path/to/file.md --inplace

Notes & tips
------------
- The script expects Python 3.6+ (uses standard library only). Run with
  `python3` to ensure the correct interpreter.
- If you want links to appear inside footnotes, the script will convert
  un-bracketed citations in footnote definitions too (they are not treated as
  bracketed by the script's bracket-splitting logic).
- If you prefer a different link target or query string (the script currently
  appends `;esv?t=biblia`), edit the `REFLY_SUFFIX` constant at the top of the
  script.

Contributing
------------
If you find cases the script misses or mis-converts (complex multi-ref
expressions, nonstandard punctuation, etc.), open a PR and add a small test
example demonstrating the expected behavior.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Match
from urllib.parse import quote


REFLY_SUFFIX = ";esv?t=biblia"


def make_reftag_url(ref_text: str) -> str:
    """Convert the visible reference text into the ref.ly URL used in the repo.

    Steps:
    - Replace the chapter:verse separator ':' with '.' for the URL path.
    - Percent-encode the string while leaving periods unencoded so the URL
      resembles the existing style (e.g. '2 Tim. 3:15–17' -> '2%20Tim.%203.15...').
    """
    # Normalize whitespace
    ref_text = " ".join(ref_text.split())
    # Use dot between chapter and verse for the URL
    ref_for_url = ref_text.replace(":", ".")
    # Normalize hyphen/dash ranges between digits to an en-dash (U+2013).
    # This ensures ranges like "15-17" or "15–17" become an en-dash which
    # is percent-encoded as %E2%80%93 in the final URL path.
    ref_for_url = re.sub(r'(?<=\d)[\-\u2013](?=\d)', '\u2013', ref_for_url)
    # Keep periods unencoded to match the style used in lbc1689-ch01.md
    encoded = quote(ref_for_url, safe='.')
    return f"https://ref.ly/{encoded}{REFLY_SUFFIX}"


# Match scripture-like references (e.g. "2 Tim. 3:15–17", "Romans 10:13-17",
# "1 Corinthians 12:1-11"). This is intentionally permissive but requires a
# chapter:verse pattern. We'll run this only on text that is NOT inside
# square-brackets so that existing bracketed references (and link texts) are
# preserved.
REFTEXT_RE = re.compile(
    r"(?P<ref>(?:[1-3]\s+)?[A-Za-z][A-Za-z0-9\.\s]{0,60}?\d{1,3}:\d{1,3}(?:[–-]\d{1,3})?(?:\s*,\s*(?:\d{1,3}(?:[–-]\d{1,3})?|\d{1,3}:\d{1,3}(?:[–-]\d{1,3})?))*)"
)


def _split_by_brackets(text: str):
  """Split text into segments that are inside square brackets and outside.

  Returns a list of tuples (segment_text, is_bracketed).
  This is a simple linear scan and treats nested brackets by counting depth.
  """
  segments = []
  cur = []
  depth = 0
  for ch in text:
    if ch == "[":
      if depth == 0 and cur:
        segments.append(("".join(cur), False))
        cur = []
      depth += 1
      cur.append(ch)
    elif ch == "]":
      cur.append(ch)
      depth = max(0, depth - 1)
      if depth == 0:
        segments.append(("".join(cur), True))
        cur = []
    else:
      cur.append(ch)

  if cur:
    segments.append(("".join(cur), depth > 0))

  return segments


def convert_text(text: str) -> str:
  """Convert scripture references that are NOT inside square brackets.

  Strategy:
  - Split the document into bracketed and non-bracketed segments.
  - Apply reference conversion only to non-bracketed segments.
  - Reassemble and return the final text.
  """

  def repl(m: Match[str]) -> str:
    ref = m.group("ref").strip()

    # If the reference contains comma-separated items after the initial
    # chapter:verse, split them and create separate links for each item.
    # Example: '1 Corinthians 12:7, 25' ->
    #   [1 Corinthians 12:7](...) , [1 Corinthians 12:25](...)
    # We parse the initial book + chapter, then split the rest on commas.
    m2 = re.match(r"^(?P<book>(?:[1-3]\s+)?[A-Za-z][A-Za-z0-9\.\s]{0,60}?)\s*(?P<chapter>\d{1,3}):(?P<rest>.*)$", ref)
    if m2:
      book = m2.group("book").strip()
      chapter = m2.group("chapter")
      rest = m2.group("rest").strip()

      # Split on commas, preserving order
      parts = [p.strip() for p in re.split(r",\s*", rest) if p.strip()]
      linked_parts = []
      for part in parts:
        # If part contains a chapter (e.g. '2:14' or '2:14-16'), use it
        if re.match(r"^\d{1,3}:", part):
          text_part = f"{book} {part}"
        else:
          # bare verse or verse-range -> prepend chapter
          text_part = f"{book} {chapter}:{part}"

        url = make_reftag_url(text_part)
        linked_parts.append(f"[{text_part}]({url})")

      # Join linked parts with comma+space to match original punctuation
      return ", ".join(linked_parts)

    # Fallback: single link for the whole matched ref
    url = make_reftag_url(ref)
    return f"[{ref}]({url})"

  parts = _split_by_brackets(text)
  out = []
  for seg, is_br in parts:
    if is_br:
      out.append(seg)
    else:
      out.append(REFTEXT_RE.sub(repl, seg))

  return "".join(out)


def main() -> None:
    p = argparse.ArgumentParser(description="Convert bracketed scripture refs to RefTag links")
    p.add_argument("input", type=Path, help="Input markdown file")
    p.add_argument("-o", "--output", type=Path, help="Output file (default: stdout) or use --inplace")
    p.add_argument("--inplace", action="store_true", help="Overwrite the input file")
    args = p.parse_args()

    if args.inplace and args.output:
        p.error("Cannot use --inplace and --output together")

    if not args.input.exists():
        p.error(f"Input file not found: {args.input}")

    text = args.input.read_text(encoding="utf-8")
    new_text = convert_text(text)

    # Always output the converted text to stdout so callers can capture it.
    print(new_text)

    # Additionally write to the requested destination if specified.
    if args.inplace:
        args.input.write_text(new_text, encoding="utf-8")
        # Keep a concise status message on stderr-friendly channel (still goes to stdout
        # here; callers can redirect if desired).
        print(f"Updated {args.input} in place.")
    elif args.output:
        args.output.write_text(new_text, encoding="utf-8")
        print(f"Wrote converted file to {args.output}.")


if __name__ == "__main__":
    main()
