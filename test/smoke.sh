#!/bin/sh
# Smoke test: build test/fixture.typ as PDF and docx, and the starter template
# as PDF, then spot-check the docx. Run from anywhere: test/smoke.sh
set -e
repo=$(dirname "$(dirname "$(readlink -f "$0")")")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

pass() { echo "ok    $1"; }
fail() { echo "FAIL  $1"; failures=$((failures + 1)); }
check() { # check "description" command...
  desc=$1; shift
  if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}
count() { # count "pattern" file-in-docx
  unzip -p "$tmp/fixture.docx" "$2" | grep -o "$1" | wc -l | tr -d ' '
}
check_count() { # check_count "description" expected "pattern" file-in-docx
  n=$(count "$3" "$4")
  if [ "$n" -eq "$2" ]; then pass "$1"; else fail "$1 (expected $2, got $n)"; fi
}

# PDF builds
check "fixture compiles to PDF" typst compile --root "$repo" "$repo/test/fixture.typ" "$tmp/fixture.pdf"

# The starter template, through a package path pointing at this checkout
mkdir -p "$tmp/packages/local/ou-tma-template"
ln -s "$repo" "$tmp/packages/local/ou-tma-template/0.1.0"
check "starter template compiles to PDF" \
  typst compile --package-path "$tmp/packages" "$repo/template/main.typ" "$tmp/main.pdf"

# docx build; any pandoc warning (e.g. an unconvertible image) is a failure
if "$repo/ou-docx" "$repo/test/fixture.typ" "$tmp/fixture.docx" >"$tmp/ou-docx.log" 2>&1 \
  && ! grep -q WARNING "$tmp/ou-docx.log"; then
  pass "fixture converts to docx without warnings"
else
  fail "fixture converts to docx without warnings"
  cat "$tmp/ou-docx.log"
  exit 1
fi

# Header filled in from tma.yaml (unquoted number, student id appended)
check_count "header has course and TMA number" 1 "ABC123 - TMA 2 - " word/header1.xml
check_count "header has author and student id" 1 "Test Student - Z0000000" word/header1.xml
check_count "header has no leftover placeholders" 0 "{{" word/header1.xml

# Title page: Title and Date styles, own section, text date from tma.yaml
check_count "title uses the Title style" 1 'w:val="Title"' word/document.xml
check_count "date from tma.yaml" 1 "1 January 2030" word/document.xml
check_count "title page is its own centred section" 1 'w:vAlign w:val="center"' word/document.xml

# Page breaks before question headings are dropped (Heading 1 starts a page);
# the one inside Question 2 becomes a Word page break
check_count "one page break inside a question" 1 'w:type="page"' word/document.xml

# Lists: (a) then (i), and the comment doesn't split the list in two
[ "$(count 'w:val="lowerLetter" */> *<w:lvlText w:val="(%1)"' word/numbering.xml)" -ge 1 ] \
  && pass "top-level lists numbered (a)" || fail "top-level lists numbered (a)"
[ "$(count 'lowerRoman' word/numbering.xml)" -ge 1 ] \
  && pass "nested lists numbered (i)" || fail "nested lists numbered (i)"
# Question 1 should be one list plus one nested list
lists=$(unzip -p "$tmp/fixture.docx" word/document.xml | grep -o '<w:numId w:val="[0-9]*"' | sort -u | wc -l | tr -d ' ')
[ "$lists" -eq 2 ] && pass "comment doesn't split the list" \
  || fail "comment doesn't split the list (expected 2 lists, got $lists)"

# Items starting with display math or a figure get a label paragraph
check_count "math and figure parts keep their labels" 2 "$(printf '\342\200\213')" word/document.xml

[ "$failures" -eq 0 ] && echo "all passed" || { echo "$failures failed"; exit 1; }
