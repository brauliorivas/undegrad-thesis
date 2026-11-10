#import "chapter-visuals.typ": chapter-figure

#let annex-c() = [
  #set par(leading: .4em, spacing: .6em)
  #counter(figure.where(kind: image)).update(0)
  #let screen = chapter-figure.with(chapter: "C")

  #heading(level: 2)[Anexo C. Pantallas del prototipo] <anexo-prototipo>

  #screen(
    [Resumen],
    align(center, image("figures/panel/resumen.jpg", width: 89%, alt: "Vista Resumen del prototipo en Figma.")),
    note: [Aquí el usuario consulta los resultados de la migración y el consumo de CPU y memoria. Con *Ver intentos fallidos* abre Logs con el filtro activo.],
  )

  #screen(
    [Logs],
    align(center, image("figures/panel/logs.jpg", width: 89%, alt: "Vista Logs del prototipo en Figma, sin filtro.")),
    note: [Aquí el usuario revisa el resultado y el detalle de cada intento reciente. Con *Solo fallidas* filtra el registro.],
  )

  #screen(
    [Logs con el filtro activo],
    align(center, image("figures/panel/fallos.jpg", width: 89%, alt: "Vista Logs del prototipo en Figma, con el filtro Solo fallidas activo.")),
    note: [Aquí el usuario distingue los rechazos de los traspasos incompletos. Con *Quitar filtro* vuelve al registro sin filtrar.],
  )

  #screen(
    [Servidores],
    align(center, image("figures/panel/servidores.jpg", width: 89%, alt: "Vista Servidores del prototipo en Figma.")),
    note: [Aquí el usuario compara los resultados por servidor HTTP. Con *Consultar los logs* vuelve al registro de migraciones.],
  )
]
