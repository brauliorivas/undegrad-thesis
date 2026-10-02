// General formatting rules for the Materia Integradora template.
#let primary-font = "Liberation Serif"
#let body-text-size = 12pt
#let chapter-heading-size = 13pt

#let bold(body) = text(weight: "bold")[#body]
#let bold-italic(body) = text(weight: "bold", style: "italic")[#body]

#let heading-level-1(title) = heading(level: 1)[#title]
#let heading-level-2(number, title) = heading(level: 2)[#number #title]
#let heading-level-3(number, title) = heading(level: 3)[#number #title]
#let heading-level-4(title, body) = [
  #par(first-line-indent: 0pt)[#h(1.27cm)#text(size: body-text-size)[#bold[#title.]] #body]
]
#let heading-level-5(title, body) = [
  #par(first-line-indent: 0pt)[#h(1.27cm)#text(size: body-text-size)[#bold-italic[#title.]] #body]
]

// Helpers that preserve APA figure and table formatting.
#let figure-apa(number, title, body, note: none) = [
  #set par(first-line-indent: 0pt)
  #bold[Figura #number] #linebreak()
  #text(style: "italic")[#title] #linebreak()
  #body
  #if note != none { [#linebreak()#bold[Nota.] #note] }
]

#let apa-table(number, title, body, note: none) = [
  #set par(first-line-indent: 0pt)
  #bold[Tabla #number] #linebreak()
  #text(style: "italic")[#title] #linebreak()
  #body
  #if note != none { [#linebreak()#bold[Nota.] #note] }
]

#let roman-page-number = context [
  #align(right)[#counter(page).display("I")]
]
#let chapter-page-number = context {
  if counter(page).get().first() > 1 {
    align(right)[#counter(page).display("1")]
  }
}

#let thesis(title: none, project-code: none, degree: none, author: none, year: none, body) = {
  set document(title: title)
  // A 1em line box plus 1em leading gives exact 2.0 line spacing.
  set text(
    font: primary-font,
    size: body-text-size,
    lang: "es",
    top-edge: 0.8em,
    bottom-edge: -0.2em,
  )
  set page(
    paper: "a4",
    margin: (top: 2.54cm, bottom: 2.54cm, left: 2.54cm, right: 2.54cm),
    header: none,
    header-ascent: 0%,
    footer: none,
  )
  set par(
    justify: false,
    first-line-indent: (amount: 1.27cm, all: true),
    leading: 1em,
    // Match the line gap across paragraph boundaries without extra spacing.
    spacing: 1em,
  )

  // APA heading hierarchy: level 1 is centered; levels 2–5 use body size.
  show heading.where(level: 1): it => block(
    width: 100%,
    above: 0pt,
    below: 1em,
    align(center)[#text(size: chapter-heading-size)[#bold[#it.body]]],
  )
  show heading.where(level: 2): it => block(
    above: 1em,
    below: 1em,
    text(size: body-text-size)[#bold[#it.body]],
  )
  show heading.where(level: 3): it => block(
    above: 1em,
    below: 1em,
    text(size: body-text-size)[#bold-italic[#it.body]],
  )

  body
}
