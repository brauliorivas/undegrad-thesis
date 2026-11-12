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
    [API], [#emph[Application Programming Interface]: interfaz de programación de aplicaciones.],
    [COAT], [#emph[Container OverlAy TCP]: arquitectura de migración de conexiones para contenedores.],
    [CPU], [#emph[Central Processing Unit]: unidad central de procesamiento.],
    [CRIU], [#emph[Checkpoint/Restore In Userspace]: captura y restauración de procesos en espacio de usuario.],
    [eBPF], [Tecnología de Linux para ejecutar programas verificados en el #emph[kernel].],
    [ESPOL], [Escuela Superior Politécnica del Litoral.],
    [HA/TCP], [Sistema de alta disponibilidad para funciones de red TCP.],
    [HTTP], [#emph[Hypertext Transfer Protocol]: protocolo de transferencia de hipertexto.],
    [kTLS], [#emph[Kernel TLS]: procesamiento de registros TLS en el #emph[kernel] de Linux.],
    [MOSN], [#emph[Modular Open Smart Network]: plataforma de #emph[proxies] escrita en Go.],
    [OTRI], [Oficina de Transferencia de Resultados de Investigación.],
    [QUIC], [Protocolo de transporte seguro con flujos multiplexados y migración de rutas.],
    [TCP], [#emph[Transmission Control Protocol]: protocolo de control de transmisión.],
    [TLS], [#emph[Transport Layer Security]: seguridad de la capa de transporte.],
  )
]

#let symbols() = [
  #front-matter-title("Simbología")
  #set par(first-line-indent: 0pt)
  #grid(columns: (2.8cm, 1fr), row-gutter: .7em,
    [%], [Porcentaje.],
    [KB], [Kilobyte: unidad de tamaño del estado transferido.],
    [µs], [Microsegundo: $10^(-6)$ segundos.],
  )
]

#let figure-index() = [
  #front-matter-title("Índice de figuras")
  #outline(target: figure.where(kind: image), title: none)
]

#let table-index() = [
  #front-matter-title("Índice de tablas")
  #outline(target: figure.where(kind: table), title: none)
]
