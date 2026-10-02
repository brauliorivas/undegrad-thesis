#import "src/style.typ": *
#import "src/data.typ": *
#import "src/front-matter.typ": *
#import "src/chapter-1.typ": chapter-one
#import "src/references.typ": ieee-references

#show: thesis.with(
  title: thesis-title,
  project-code: project-code,
  degree: degree,
  author: author,
  year: year,
)

#cover()
#pagebreak()
#explicit-declaration()
#pagebreak()
#examiners()

// Roman numbering starts at I. The cover, declaration, and examiner pages are not numbered.
#set page(numbering: "I", header: roman-page-number, footer: none)
#counter(page).update(1)
#pagebreak()
#summary()
#pagebreak()
#abstract()
#pagebreak()
#table-of-contents()
#pagebreak()
#abbreviations()
#pagebreak()
#symbols()
#pagebreak()
#figure-index()

// Chapter 1 starts Arabic numbering. Its first page counts as 1 but does not display it.
#set page(numbering: "1", header: chapter-page-number, footer: none)
#counter(page).update(1)
#pagebreak()
#chapter-one()

// After adding citations such as @rfc9293, uncomment this line to render IEEE references.
// #ieee-references()
