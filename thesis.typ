#import "src/style.typ": *
#import "src/data.typ": *
#import "src/front-matter.typ": *
#import "src/chapter-1.typ": chapter-one
#import "src/chapter-2.typ": chapter-two
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
#pagebreak()
#table-index()

// Chapter 1 starts Arabic numbering. Its first page counts as 1 but does not display it.
#set page(numbering: "1", header: chapter-page-number, footer: none)
#counter(page).update(1)
#pagebreak()
#chapter-one()

#pagebreak()
#chapter-two()

#pagebreak()
#set page(numbering: none, header: none)
#ieee-references()


#pagebreak()
#set page(numbering: "1", header: chapter-page-number)
#heading-level-1("ANEXOS")
#heading(level: 2)[Anexo A. Historias de usuario firmadas] <anexo-historias>

Historias de usuario y sus criterios de aceptación firmadas por el cliente.

#let signed-stories = "files/historias-de-usuario-signed.pdf"
#pdf.attach(
  signed-stories,
  mime-type: "application/pdf",
  description: "Historias de usuario y criterios de aceptación con firma electrónica",
)

#for number in range(1, 4) {
  // Typst does not import the signature widget. Its visible appearance is
  // flattened into a copy of page 3 while the signed original stays attached.
  let (source, source-page) = if number == 3 {
    ("files/historias-de-usuario-pagina-firma.pdf", 1)
  } else {
    (signed-stories, number)
  }
  page(paper: "a4", flipped: true, margin: 0pt, numbering: none, header: none)[
    #image(
      source,
      page: source-page,
      width: 100%,
      alt: "Historias de usuario y criterios de aceptación. Página " + str(number) + " de 3.",
    )
  ]
}
