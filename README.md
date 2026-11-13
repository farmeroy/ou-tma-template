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

Each `= Question n` heading appears in the page header. Numbered lists use `(a)(i)` numbering.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `course` | `""` | Course code, e.g. `"MST368"` |
| `number` | `""` | TMA number, e.g. `"01"` |
| `author` | `""` | Your name |
| `student-id` | `none` | Shown after your name if set |
| `date` | `datetime.today()` | Date on the title page |
| `enum-numbering` | `"(a)(i)"` | Numbering pattern for `+` lists |
