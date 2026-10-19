// Native figures retain counters, references and automatic indexes.
// Captions precede the visual; notes belong to its body and stay out of indexes.
#let caption-above(it) = block(width: 100%, breakable: false)[
  #set align(left)
  #set par(first-line-indent: 0pt)
  #strong[#it.supplement #context it.counter.display(it.numbering)]
  #linebreak()
  #emph[#it.body]
]

#let chapter-visual(title, body, kind: image, note: none, target: none) = {
  set par(first-line-indent: 0pt)
  set figure.caption(position: top)
  show figure.caption: caption-above
  let visual = figure(
    [
      #body
      #if note != none {
        v(.5em)
        block(width: 100%)[
          #set align(left)
          #emph[Nota.] #note
        ]
      }
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

// Tables use the body font and single line spacing inside their cells.
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
