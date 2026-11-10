// Native figures retain counters, references and automatic indexes.
#let visual-note(note, alignment: left) = block(width: 100%, above: .5em)[
  #set align(alignment)
  #emph[Nota.] #note
]

#let format-caption(it, note: none, alignment: center) = block(width: 100%, breakable: false)[
  #set align(alignment)
  #set par(first-line-indent: 0pt)
  #strong[#it.supplement #context it.counter.display(it.numbering)]
  #linebreak()
  #emph[#it.body]
  #if note != none { visual-note(note, alignment: alignment) }
]

#let chapter-visual(title, body, kind: image, note: none, target: none, chapter: 1) = {
  let is-table = kind == table
  set par(first-line-indent: 0pt)
  set figure.caption(position: if is-table { top } else { bottom })
  show figure.caption: format-caption.with(
    note: if is-table { none } else { note },
    alignment: if is-table { left } else { center },
  )
  let visual = figure(
    [
      #body
      #if is-table and note != none { visual-note(note) }
    ],
    kind: kind,
    supplement: if is-table { [Tabla] } else { [Figura] },
    numbering: n => str(chapter) + "." + str(n),
    caption: title,
    gap: .5em,
  )
  if target == none { visual } else { [#visual#target] }
}

#let chapter-figure(title, body, note: none, target: none, chapter: 1) = chapter-visual(title, body, note: note, target: target, chapter: chapter)
#let chapter-table(title, body, note: none, target: none, chapter: 1) = chapter-visual(title, body, kind: table, note: note, target: target, chapter: chapter)

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
