// Generic Open University TMA template.
//
// Usage:
//   #import "@local/ou-tma-template:0.1.0": tma
//   #show: tma.with(course: "MST368", number: "01", author: "Your Name", student-id: "Z1234567")

#let tma(
  course: "",
  number: "",
  author: "",
  student-id: none,
  date: datetime.today(),
  enum-numbering: "(a)(i)",
  body,
) = {
  let title-text = course + " - TMA " + number
  let author-name = if student-id == none { author } else { author + " - " + student-id }

  set document(title: title-text, author: author)

  // Header shows the most recent level-1 heading on or before the current page
  let doc-header = context {
    let page-num = here().page()
    let headings = query(heading.where(level: 1))
    let on-or-before = headings.filter(h => h.location().page() <= page-num)
    let current = if on-or-before.len() > 0 { on-or-before.last().body } else { [] }

    emph[#title-text - #current]
    h(1fr)
    emph[#author-name]
  }

  set page(paper: "a4", numbering: none, header: none)
  set enum(numbering: enum-numbering, spacing: 2em)
  set math.mat(column-gap: 1em, row-gap: .5em)

  // Title page
  align(center + horizon)[
    #text(size: 24pt, weight: "bold")[#title-text]
    #v(1em)
    #text(size: 12pt)[#author-name
    #v(1em)
    #date.display()]
  ]

  pagebreak()

  // Body pages
  set page(
    numbering: "1 of 1",
    margin: (top: 4cm, x: 4cm),
    header: pad(x: -2cm)[#doc-header],
  )
  counter(page).update(1)
  show heading: set block(below: 2.5em)

  body
}
