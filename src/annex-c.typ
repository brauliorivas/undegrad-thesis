#import "chapter-visuals.typ": chapter-figure

#let annex-c() = [
  #set par(leading: .4em, spacing: .6em)
  #counter(figure.where(kind: image)).update(0)
  #let screen = chapter-figure.with(chapter: "C")

  #heading(level: 2)[Anexo C. Pantallas del prototipo] <anexo-prototipo>

  #screen(
    [Resumen],
    align(center, image("figures/panel/resumen.png", width: 89%, alt: "Vista Resumen del prototipo en Figma.")),
    note: [El resumen muestra la proporción de cada resultado y el consumo adicional de CPU y memoria. Con *Ver intentos fallidos* abre Logs con el filtro activo.],
  )

  #screen(
    [Logs],
    align(center, image("figures/panel/logs.png", width: 89%, alt: "Vista Logs del prototipo en Figma, sin filtro.")),
    note: [Cada intento tiene un ID propio, aunque comparta los PID con otros intentos. El usuario puede ordenar el registro con *Hora*, filtrar los intentos de las 10:24 o abrir la vista *Solo fallidas*.],
  )

  #screen(
    [Logs con el filtro activo],
    align(center, image("figures/panel/fallos.png", width: 89%, alt: "Vista Logs del prototipo en Figma, con el filtro Solo fallidas activo.")),
    note: [El registro distingue los rechazos de los traspasos incompletos e indica que, en ambos casos, se debe mantener el proceso anterior. Con *Quitar filtro* vuelve al registro sin filtrar.],
  )

  #screen(
    [Servidores],
    align(center, image("figures/panel/servidores.png", width: 89%, alt: "Vista Servidores del prototipo en Figma.")),
    note: [El usuario compara los resultados por servidor HTTP y puede volver al registro desde la pestaña *Logs*.],
  )
]
