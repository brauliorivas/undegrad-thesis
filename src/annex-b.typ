#import "chapter-visuals.typ": ruled-table
#import "style.typ": figma-prototype-note

#let annex-b() = [
  #heading(level: 2)[Anexo B. Pruebas de usuario del panel] <anexo-pruebas>

  #heading(level: 3)[Guía de la sesión]

  La sesión empieza en la vista Resumen del prototipo de Figma.#figma-prototype-note() Quien modera ajusta la vista a la pantalla. Cada participante revisa una actualización simulada y explica en voz alta lo que observa.

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

  #pagebreak()
  #heading(level: 3)[Fichas de registro]

  Aquí se encuentran las fichas de registro.

  #let participants = (
    (
      name: [Angel Pilataxi],
      decision: [Decisión compatible],
      observation: [Mantendría el proceso anterior en ambos casos.],
      comment: [Propone mostrar porcentajes en las barras de Resumen para evitar repetir los conteos de la parte superior.],
    ),
    (
      name: [Carlos Lopez],
      decision: [Decisión compatible],
      observation: [Mantendría el proceso ante el rechazo. En el intento incompleto, esperaría antes de retirarlo.],
      comment: [Sin comentarios adicionales.],
    ),
    (
      name: [Jose Adrian],
      decision: [Respuesta parcial],
      observation: [Dudó sobre si retirar el proceso anterior ante el intento incompleto.],
      comment: [Prefiere una sola forma de ir a Logs desde Servidores, ya sea la pestaña superior o el botón inferior.],
    ),
    (
      name: [Alan Aguilar],
      decision: [Respuesta parcial],
      observation: [Mantendría el proceso ante el rechazo. Su decisión sobre el intento incompleto quedó sin registrar.],
      comment: [Valoró que el panel presenta una cantidad manejable de información.],
    ),
    (
      name: [Juan Munizaga],
      decision: [Confusión de intentos],
      observation: [Interpretó el rechazo y el intento incompleto como un mismo intento porque ambos registros tenían los mismos PID.],
      comment: [Preguntó por el significado de la línea base y de la abreviatura pp.],
    ),
    (
      name: [Sebastián Barco],
      decision: [Decisión compatible],
      observation: [Mantendría el proceso en ambos casos y revisaría qué ocurrió en cada intento antes de retirarlo.],
      comment: [Propone ordenar los registros desde los encabezados de las columnas y agregar filtros por columna, por ejemplo, por hora.],
    ),
  )

  #for (index, participant) in participants.enumerate() {
    if index in (2, 4) { pagebreak() }
    block(breakable: false, width: 100%)[
      #set par(first-line-indent: 0pt)
      *Participante #(index + 1)*

      #ruled-table(
        columns: (1fr, 1fr, 2.7fr),
        table.cell(colspan: 2)[*Nombre*], [*Perfil de usuario*],
        table.cell(colspan: 2, participant.name), [Operador del #emph[proxy] (perfil evaluado)],
        [*Tarea*], [*Resultado*], [*Observaciones*],
        [1. Resumen], [Correcta], [],
        [2. Recursos], [Correcta], [],
        [3. Fallos], participant.decision, participant.observation,
        [4. Servidores], [Correcta], [],
        table.cell(colspan: 2)[*Resultado general*], [Tareas 1, 2 y 4 correctas.],
        table.cell(colspan: 3)[*Comentario adicional.* #participant.comment],
      )
    ]
  }
]
