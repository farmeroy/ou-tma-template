// Smoke test document: exercises each docx conversion the filter handles.
// Imports the repo's lib.typ directly so it tests this checkout.
#import "../lib.typ": tma

#show: tma.with(..yaml("tma.yaml"))

= Question 1
+ Plain text part with inline math $x^2$
+ $ mat(1, 0; 0, 1) $
+ #figure(image("figure.png", width: 2cm), caption: [A circle])
+ + Nested part
  + Another nested part

// A comment inside the list should not restart its numbering
+ Part after a comment

#pagebreak()

= Question 2

#table(
  columns: 2,
  table.header[Left][Right],
  [1], [2],
)

Text before a page break inside a question.

#pagebreak()

Text after it.
