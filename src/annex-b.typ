#import "chapter-visuals.typ": ruled-table

#let annex-b() = [
  #heading(level: 2)[Anexo B. Pruebas de usuario del panel] <anexo-pruebas>

  #heading(level: 3)[Guía de la sesión]

  La sesión empieza en la vista Resumen del #link("https://www.figma.com/proto/h3bnz9BI44GdkIczqj9SYo/Migraci%C3%B3n-TCP-%C2%B7-Panel-del-proxy?node-id=4-38&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1&starting-point-node-id=4%3A38")[prototipo de Figma]. Quien modera ajusta la vista a la pantalla. Cada participante revisa una actualización simulada y explica en voz alta lo que observa.

  #ruled-table(
    columns: (auto, 1fr, 1.2fr),
    table.header([*Tarea*], [*Consigna*], [*Criterio para quien modera*]),
    [1. Resumen],
    [Explica cómo salió el traspaso y cuánto tardó en promedio.],
    [Reconoce 36 éxitos de 40 intentos, 3 rechazos y 1 incompleto. Lee 42 ms de media para los éxitos.],
    [2. Recursos],
    [¿Cuánto cambió el uso de CPU y memoria durante la migración? ¿Con qué se compara?],
    [Lee 4,2 puntos porcentuales de CPU y 12 MiB de RAM adicionales frente a la misma carga sin actualización.],
    [3. Fallos],
    [Deja visibles solo los fallos. ¿Qué pasó a las 10:24:45 y a las 10:24:26? ¿Retirarías el proceso anterior?],
    [Distingue el rechazo por esquema incompatible de la confirmación pendiente. Esperaría a resolver los fallos antes del retiro.],
    [4. Servidores],
    [¿Qué servidor concentra más fallos? ¿Entre qué procesos ocurre el traspaso?],
    [Identifica `backend-02` con 3 fallos. Distingue los procesos locales del proxy (PID 7312 y 7486) del servidor asociado a las conexiones.],
  )

  Quien modera lee solo la consigna de cada tarea. Al cierre pregunta qué costó encontrar y qué cambiaría del panel.

  #heading(level: 3)[Fichas de registro]

  Aquí se encuentran las fichas de registro.

  #for number in range(1, 6) {
    if number == 4 { pagebreak() }
    block(breakable: false, width: 100%)[
      #set par(first-line-indent: 0pt)
      *Participante #number*

      #ruled-table(
        columns: (1fr, 1fr, 2.7fr),
        table.cell(colspan: 2)[*Nombre*], [*Perfil de usuario*],
        table.cell(colspan: 2)[#v(8pt)], [],
        [*Tarea*], [*Resultado*], [*Observaciones*],
        [1. Resumen], [], [],
        [2. Recursos], [], [],
        [3. Fallos], [], [],
        [4. Servidores], [], [],
        table.cell(colspan: 2)[*Resultado general*], [],
      )
    ]
  }
]
