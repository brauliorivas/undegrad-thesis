// Native figures retain counters, references and automatic indexes.
// Notes are added while rendering the caption, keeping indexes note-free.
#let caption-below(it, note: none) = block(width: 100%, breakable: false)[
  #set align(center)
  #set par(first-line-indent: 0pt)
  #strong[#it.supplement #context it.counter.display(it.numbering)]
  #h(.25em)
  #emph[#it.body]
  #if note != none { footnote(note) }
]

#let chapter-visual(title, body, kind: image, note: none, target: none) = {
  set par(first-line-indent: 0pt)
  set figure.caption(position: bottom)
  show figure.caption: it => caption-below(it, note: note)
  let visual = figure(
    body,
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
