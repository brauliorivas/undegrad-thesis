#import "data.typ": *
#import "style.typ": bold

#let cover() = [
  #set par(first-line-indent: 0pt, leading: 1em)
  #align(center)[
    #v(1.25cm)
    #university
    #v(1.05cm)
    #faculty
    #v(3.3cm)
    #bold[#thesis-title]
    #v(0.6cm)
    #project-code #linebreak()
    Proyecto Integrador
    #v(0.65cm)
    Previo la obtención del título de: #linebreak()
    #degree
    #v(2.3cm)
    Presentado por: #linebreak()
    #author
    #v(2.3cm)
    #city #linebreak()
    Año: #year
  ]
]

#let explicit-declaration() = [
  #set par(first-line-indent: 0pt, leading: 1em, spacing: 1em)
  #align(center)[#bold[Declaración Expresa]]
  #v(1.2em)
  Yo, #author, acuerdo y reconozco que:

  La titularidad de los derechos patrimoniales de autor (derechos de autor) del proyecto de graduación corresponderá al autor o autores, sin perjuicio de lo cual la ESPOL recibe en este acto una licencia gratuita de plazo indefinido para el uso no comercial y comercial de la obra con facultad de sublicenciar, incluyendo la autorización para su divulgación, así como para la creación y uso de obras derivadas. En el caso de usos comerciales se respetará el porcentaje de participación en beneficios que corresponda a favor del autor o autores.

  La titularidad total y exclusiva sobre los derechos patrimoniales de patente de invención, modelo de utilidad, diseño industrial, secreto industrial, software o información no divulgada que corresponda o pueda corresponder respecto de cualquier investigación, desarrollo tecnológico o invención realizada por mí durante el desarrollo del proyecto de graduación, pertenecerán de forma total, exclusiva e indivisible a la ESPOL, sin perjuicio del porcentaje que me corresponda de los beneficios económicos que la ESPOL reciba por la explotación de mi innovación, de ser el caso.

  En los casos donde la Oficina de Transferencia de Resultados de Investigación (OTRI) de la ESPOL comunique al autor que existe una innovación potencialmente patentable sobre los resultados del proyecto de graduación, no se realizará publicación o divulgación alguna, sin la autorización expresa y previa de la ESPOL.

  #v(1.2em)
  Guayaquil, #box(width: 4cm, stroke: (bottom: .5pt))[ ] del #year.
  #v(4.2cm)
  #align(center)[#line(length: 7cm) #linebreak() #author]
]

#let examiners() = [
  #set par(first-line-indent: 0pt)
  #align(center)[#bold[Evaluadores]]
  #v(6.5cm)
  #grid(columns: (1fr, 1fr), column-gutter: 1.5cm,
    align(center)[#line(length: 6.2cm) #linebreak() #course-instructor #linebreak()
      Profesor de Materia],
    align(center)[#line(length: 6.2cm) #linebreak() #project-advisor #linebreak()
      Tutor de proyecto],
  )
  #v(1.1cm)
  #align(center)[(Nombres completos y firma electrónica)]
]

#let front-matter-title(title) = [
  #set par(first-line-indent: 0pt)
  #align(center)[#bold[#title]]
  #v(1em)
]

#let summary() = [
  #front-matter-title("Resumen")
  #set par(first-line-indent: 0pt)
  [Escriba aquí un único párrafo de 150 a 200 palabras. Debe presentar, en estilo impersonal, una breve introducción, los objetivos, la hipótesis y la justificación en presente; el desarrollo, materiales, equipos, técnicas y resultados principales en pasado; y las conclusiones generales en presente.]
  #v(1em)
  #bold[Palabras clave:] migración TCP, proxies, balanceo de carga, conexiones persistentes
]

#let abstract() = [
  #front-matter-title("Abstract")
  #set text(style: "italic")
  #set par(first-line-indent: 0pt)
  [Write here the English version of the Resumen as one paragraph of 150 to 200 words.]
  #v(1em)
  #bold[Keywords:] TCP migration, proxies, load balancing, persistent connections
]

#let table-of-contents() = [
  #front-matter-title("Índice general")
  #outline(title: none, depth: 3, indent: auto)
]

#let abbreviations() = [
  #front-matter-title("Abreviaturas")
  #set par(first-line-indent: 0pt)
  #grid(columns: (2.8cm, 1fr), row-gutter: .7em,
    [TCP], [Transmission Control Protocol],
    [IP], [Internet Protocol],
    [NAT], [Network Address Translation],
  )
]

#let symbols() = [
  #front-matter-title("Simbología")
  #set par(first-line-indent: 0pt)
  #grid(columns: (2.8cm, 1fr), row-gutter: .7em,
    [$t$], [Tiempo],
    [$R$], [Tasa de transferencia],
  )
]

#let figure-index() = [
  #front-matter-title("Índice de figuras")
  #outline(target: figure.where(kind: image), title: none)
  #v(1em)
  #set par(first-line-indent: 0pt)
  [Las figuras que se añadan al documento aparecerán aquí automáticamente.]
]
