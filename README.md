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

Start a new TMA from the template:

```sh
typst init @local/ou-tma-template:0.1.0 tma01
```

Or add this to the top of an existing `.typ` file:

```typst
#import "@local/ou-tma-template:0.1.0": tma

#show: tma.with(
  course: "MST368",
  number: "01",
  author: "Your Name",
  student-id: "Z1234567",
)

= Question 1
+ Part (a)
+ + Part (b)(i)
  + Part (b)(ii)
```

Each `= Question n` heading starts a new page and appears in the page header. Numbered lists use `(a)(i)` numbering.

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

Differences from the PDF: figures aren't numbered or centred, footers show just the page number (not "1 of N"), and the font is Cambria.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `course` | `""` | Course code, e.g. `"MST368"` |
| `number` | `""` | TMA number, e.g. `"01"` |
| `author` | `""` | Your name |
| `student-id` | `none` | Shown after your name if set |
| `date` | today | Date on the title page, e.g. `datetime(year: 2026, month: 11, day: 14)` |
| `enum-numbering` | `"(a)(i)"` | Numbering pattern for `+` lists |
