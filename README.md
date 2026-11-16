# ou-tma-template

A [Typst](https://typst.app) template for Open University TMAs: a title page, then A4 pages with a header showing the course, TMA number, current question and author, plus "n of N" page numbers.

## Install

Clone it and symlink it into your local Typst packages directory:

```sh
git clone https://github.com/<you>/ou-tma-template.git ~/Documents/OpenUniversity/ou-tma-template
mkdir -p ~/.local/share/typst/packages/local/ou-tma-template
ln -s ~/Documents/OpenUniversity/ou-tma-template ~/.local/share/typst/packages/local/ou-tma-template/0.1.0
```

(On macOS the packages directory is `~/Library/Application Support/typst/packages`.)

## Use

Start a new TMA from the template, then fill in `tma01/tma.yaml`:

```sh
typst init @local/ou-tma-template:0.1.0 tma01
```

Or put a `tma.yaml` next to an existing `.typ` file:

```yaml
course: MST368
number: "01"
author: Your Name
student-id: Z1234567
# date: 14 November 2026    # defaults to today
```

and add this to the top of the `.typ` file:

```typst
#import "@local/ou-tma-template:0.1.0": tma

#show: tma.with(..yaml("tma.yaml"))

= Question 1
+ Part (a)
+ + Part (b)(i)
  + Part (b)(ii)
```

Each `= Question n` heading starts a new page and appears in the page header. Numbered lists use `(a)(i)` numbering.

You can also skip the YAML file and pass the options directly, e.g. `#show: tma.with(course: "MST368", number: "01", author: "Your Name")`.

## Word (.docx) output

For courses that want a .docx, convert the same file:

```sh
ou-docx tma01.typ            # writes tma01.docx
```

The .docx has the same layout as the PDF: title page, wide margins, a header with the current question and your name, page numbers from the first question, and `(a)(i)` lists. Equations become editable Word equations.

Install it by putting the script on your `PATH`:

```sh
ln -s ~/Documents/OpenUniversity/ou-tma-template/ou-docx ~/.local/bin/ou-docx
```

Requires pandoc 3.14 or newer (Ubuntu's package is too old; install the .deb from https://github.com/jgm/pandoc/releases), plus `zip` and `unzip`.

How it works: pandoc reads the Typst file (the template detects pandoc and skips the page layout it can't handle), `docx/reference.docx` supplies the page layout, and `docx/ou.lua` fixes the title page, page breaks and list numbering.

To change the Word margins, fonts or styles, edit the values at the top of `docx/make-reference.py` and run `python3 docx/make-reference.py` to rebuild `docx/reference.docx`.

Differences from the PDF: figures aren't numbered or centred, footers show just the page number (not "1 of N"), and the font is Cambria.

SVG images need `rsvg-convert` (Ubuntu: `librsvg2-bin`) to go into a .docx; PNG and JPEG work as they are.

## Testing

```sh
test/smoke.sh
```

Builds `test/fixture.typ` (made-up student and answers) as PDF and .docx, compiles the starter template, and spot-checks the .docx: header text, title page, page breaks and list numbering.

## Options

These work as keys in `tma.yaml` or as arguments to `tma.with(...)`.

| Option | Default | Description |
| --- | --- | --- |
| `course` | `""` | Course code, e.g. `MST368` |
| `number` | `""` | TMA number, e.g. `"01"` (quote it to keep the leading zero) |
| `author` | `""` | Your name |
| `student-id` | none | Shown after your name if set |
| `date` | today | Date on the title page, as text (e.g. `14 November 2026`) or a Typst `datetime` |
| `enum-numbering` | `"(a)(i)"` | Numbering pattern for `+` lists in the PDF (the .docx always uses `(a)(i)`) |
