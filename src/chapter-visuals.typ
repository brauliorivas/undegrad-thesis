// Native figure elements retain counters, references and automatic indexes.
#let chapter-visual(title, body, kind: image, note: none, target: none) = {
  set par(first-line-indent: 0pt)
  set figure.caption(position: top)
  show figure.caption: it => block(width: 100%, sticky: true, breakable: false)[
    #set align(left)
    #strong[#it.supplement #context it.counter.display(it.numbering)]
    #linebreak()
    #emph[#it.body]
  ]
  let visual = figure(
    [
      #body
      #if note != none [
        #v(.5em)
        #align(left)[#par(first-line-indent: 0pt)[#emph[Nota.] #note]]
      ]
    ],
    kind: kind,
    supplement: if kind == table { [Tabla] } else { [Figura] },
    numbering: n => "1." + str(n),
    caption: title,
    gap: .5em,
  )
  if target == none { visual } else { [#visual#target] }
}

#let chapter-figure(title, body, note: none, target: none) = chapter-visual(title, body, note: note, target: target)
#let chapter-table(title, body, note: none, target: none) = chapter-visual(title, body, kind: table, note: note, target: target)

// APA tables retain the body font and size, with single line spacing inside.
#let ruled-table(columns: auto, ..cells) = {
  set par(first-line-indent: 0pt, leading: 0pt, spacing: 0pt)
  table(
    columns: columns,
    align: left + top,
    inset: (x: 5pt, y: 6pt),
    stroke: (x: none, y: .5pt),
    ..cells,
  )
}
