#import "style.typ": heading-level-1, heading-level-2, heading-level-3
#import "chapter-visuals.typ": chapter-figure, chapter-table, ruled-table

#let chapter-two() = [
  #counter(figure.where(kind: image)).update(0)
  #counter(figure.where(kind: table)).update(0)
  #let chapter-figure = chapter-figure.with(chapter: 2)
  #let chapter-table = chapter-table.with(chapter: 2)

  #heading-level-1("CAPÍTULO 2")
  #heading-level-2("2.1", "Metodología de diseño")

  Se planteó un desarrollo experimental para estudiar la migración de conexiones durante una actualización del #emph[proxy]. Se tomó como unidad de transferencia el par de conexiones cliente–#emph[proxy] y #emph[proxy]–servidor, junto con su estado TLS y HTTP. El diseño se orientó a conservar la comunicación y permitir el retiro del proceso anterior antes de completar los mensajes en curso.

  El trabajo se organizó en cuatro etapas: comparación de alternativas, definición de la arquitectura, implementación incremental y evaluación controlada. Los requisitos del capítulo 1 guiaron la selección. Este capítulo documentó el diseño propuesto y el procedimiento previsto para validarlo. La selección definitiva de las dependencias quedó condicionada a las pruebas de exportación y restauración, todavía pendientes en este avance.

  #heading-level-3("2.1.1", "Historias de usuario")

  Las historias de usuario recogen las necesidades del desarrollador de #emph[proxies], del operador, del usuario del servicio y del investigador. Los criterios de aceptación completos y el documento firmado se incluyen en el #link(<anexo-historias>)[Anexo A].

  - *HU-01. Integración de la biblioteca.* Como desarrollador de #emph[proxies], quiero integrar la biblioteca Rust mediante una interfaz documentada para registrar, transferir y restaurar pares de conexiones, y emplear adaptadores TLS 1.3 y HTTP/1.1 con una interfaz común.
  - *HU-02. Transferencia del par de conexiones.* Como operador, quiero trasladar al nuevo proceso las conexiones cliente–#emph[proxy] y #emph[proxy]–servidor para mantener la comunicación durante la actualización, sin reconexiones y conservando la asociación de cada solicitud con su destino y respuesta.
  - *HU-03. Conservación del estado TLS.* Como operador, quiero conservar los contextos TLS 1.3 de ambos lados y sus datos pendientes para continuar el intercambio cifrado sin un nuevo establecimiento de sesión ni alteración de los datos.
  - *HU-04. Continuidad de las comunicaciones HTTP.* Como usuario del servicio, quiero que mis intercambios HTTP/1.1 continúen durante la actualización sin reconectarme ni repetir solicitudes. Esto requiere conservar el progreso, los búferes y las escrituras parciales, así como reutilizar las conexiones persistentes.
  - *HU-05. Coordinación y retiro del proceso anterior.* Como operador, quiero retirar el proceso anterior solo después de confirmar que el nuevo asumió todas las comunicaciones que debía recibir. Si falla la restauración o falta su confirmación, quiero conocer el resultado y mantener el proceso anterior.
  - *HU-06. Protección del estado transferido.* Como operador, quiero limitar el acceso al canal local y al estado criptográfico a procesos autorizados para impedir la entrega de descriptores o secretos a terceros.
  - *HU-07. Evaluación de continuidad y costo.* Como investigador, quiero comparar la migración, el drenaje y la ejecución sin actualización bajo cargas equivalentes para verificar la continuidad y la integridad de las comunicaciones y medir los tiempos de traspaso y retiro, la pausa y el consumo de recursos.

  La @casos-de-uso identifica las interacciones de cada actor con el #emph[proxy], la biblioteca y el panel. El operador inicia la migración y revisa su resultado. El usuario del servicio realiza su solicitud HTTP a través del #emph[proxy] y espera que el intercambio continúe durante la actualización.

  #chapter-figure(
    [Casos de uso del proxy de demostración y la biblioteca de migración],
    image("figures/diagrams/casos-de-uso.svg", width: 95%, alt: "El usuario realiza solicitudes HTTP, el desarrollador integra la biblioteca, el operador solicita y revisa migraciones y el investigador consulta métricas."),
    target: label("casos-de-uso"),
  )

  #heading-level-2("2.2", "Alternativas y selección de la solución")

  Se compararon tres mecanismos de actualización. El drenaje mantuvo su papel de referencia, porque permite atender las conexiones existentes en el proceso anterior mientras la nueva versión recibe tráfico. Envoy documenta que su reinicio no transfiere esas conexiones @envoy-hot-restart. Para este proyecto, esa dependencia de la duración de las comunicaciones impidió elegirlo como solución principal.

  La segunda alternativa consistió en capturar y restaurar el proceso o reconstruir sus conexiones mediante CRIU y `TCP_REPAIR`. Este último permite consultar y restituir colas y números de secuencia TCP @criu-tcp. Se consideró adecuado para escenarios de restauración, pero el reemplazo por otra versión del programa exigía resolver además la compatibilidad del estado de aplicación. Reconstruir el transporte tampoco resultó necesario para el escenario local, donde podía conservarse el recurso existente.

  La tercera alternativa fue una transferencia cooperativa de descriptores y estado explícito. `SCM_RIGHTS` permite que otro proceso reciba una referencia al mismo recurso abierto @linux-unix. Se seleccionó este mecanismo para conservar los dos #emph[sockets] TCP y trasladar por separado el estado TLS/HTTP que permaneciera en memoria. La @alternativas-diseno resume la decisión.

  #chapter-table(
    [Comparación de alternativas para la actualización local],
    ruled-table(
      columns: (1.1fr, 2.2fr, 2.7fr),
      table.header([*Alternativa*], [*Ventaja para el proyecto*], [*Limitación y decisión*]),
      [Drenaje], [Conserva las comunicaciones en el proceso anterior.], [Su retiro depende del trabajo pendiente. Se conservó como referencia experimental.],
      [Captura y restauración], [Recupera recursos y estado de ejecución.], [Requiere tratar la compatibilidad con otra versión. No se eligió para el traspaso local.],
      [Descriptores y estado explícito], [Conserva los recursos TCP y permite definir el estado intercambiado.], [Exige cooperación y adaptadores TLS/HTTP. Se seleccionó para el prototipo.],
    ),
    note: [Comparación cualitativa respecto al alcance del capítulo 1.],
    target: label("alternativas-diseno"),
  )

  Para organizar la solución, se consideraron una biblioteca integrada y un servicio supervisor independiente. Se eligió integrar la biblioteca en ambos procesos y comunicar las instancias directamente. Esta organización permitió definir los puntos de pausa y la representación del estado dentro de cada instancia.

  Se mantuvo Rust como lenguaje de implementación por su gestión explícita de recursos y sus reglas de propiedad @rust-ownership. También se consideró un núcleo en C por su interoperabilidad, pero no eliminaba la necesidad de adaptar cada biblioteca TLS/HTTP. Se separó el protocolo de intercambio de las estructuras internas de Rust para facilitar futuras implementaciones. Una interfaz binaria compatible con C quedó como posible extensión, sin añadirla a la entrega principal.

  #heading-level-2("2.3", "Diseño conceptual y componentes")

  Se dividió la biblioteca en un núcleo de coordinación, un transporte local y adaptadores de protocolo. El núcleo se encargó conceptualmente del ciclo de migración y de la decisión de activar o cancelar el traspaso. El transporte se destinó al envío de descriptores, mensajes de control y estado serializado. Los adaptadores quedaron responsables de pausar el procesamiento, capturar el estado y reconstruirlo en el proceso nuevo. La @arquitectura-migracion presenta esta separación.

  #chapter-figure(
    [Componentes de la migración entre procesos],
    {
      set par(first-line-indent: 0pt, leading: 3pt, spacing: 4pt)
      let instance(title) = block(width: 100%, inset: 8pt, stroke: .6pt)[
        #align(center)[*#title*]
        #line(length: 100%, stroke: .4pt)
        Proxy y estado de la comunicación \
        Adaptadores TLS / HTTP \
        Núcleo de coordinación y transporte
      ]
      grid(columns: (1fr, 1fr), gutter: 12pt,
        instance([Proceso anterior]), instance([Proceso nuevo]),
      )
      v(6pt)
      align(center)[Canal Unix: control, descriptores y estado ↔]
      v(6pt)
      block(width: 100%, inset: 8pt, stroke: .6pt)[
        #align(center)[Linux: los mismos dos sockets TCP durante el traspaso]
      ]
    },
    note: [El proceso nuevo permanece inactivo sobre las conexiones recibidas hasta obtener autorización. La coexistencia de descriptores no autoriza el procesamiento simultáneo.],
    target: label("arquitectura-migracion"),
  )

  El #emph[proxy] de demostración se delimitó a un intercambio HTTP/1.1 activo por par de conexiones, con TLS 1.3 establecido en ambos lados. Se incluyeron conexiones persistentes y cuerpos de longitud conocida o codificados por fragmentos. Se mantuvieron las restricciones y exclusiones del capítulo 1, con HTTP/2 como extensión opcional.

  #heading-level-3("2.3.1", "Vistas de la arquitectura")

  El modelo 4+1 de Kruchten describe la arquitectura desde cuatro perspectivas complementarias. Los escenarios relacionan esas perspectivas y permiten comprobar que, en conjunto, cubren el comportamiento esperado @kruchten-1995.

  - *Vista lógica.* El coordinador controla el traspaso de cada par de conexiones. Los adaptadores conservan el estado TLS y HTTP, y el módulo de observabilidad registra el resultado.
  - *Vista de procesos.* El proceso anterior pausa las operaciones y envía los descriptores y el estado. El proceso nuevo restaura el par y espera la autorización de activación para reanudar la comunicación. En cada fase solo un proceso está autorizado para operar sobre el par.
  - *Vista de desarrollo.* La biblioteca Rust separa el núcleo de coordinación, el transporte Unix, los adaptadores de protocolo y la instrumentación. La @modulos-dependencias muestra cómo el #emph[proxy] de demostración accede a esos módulos mediante la interfaz de la biblioteca.
  - *Vista física.* Las dos instancias del #emph[proxy] coexisten en el mismo equipo Linux y se comunican mediante un canal Unix de acceso restringido. El cliente y el servidor conservan sus conexiones TCP con el #emph[proxy].
  - *Escenarios (+1).* Un cuerpo HTTP incompleto debe continuar tras el traspaso (HU-02 a HU-05). Ante un estado incompatible se rechaza el intento y se impide el retiro del proceso anterior (HU-05). Un proceso no autorizado queda excluido del canal de transferencia (HU-06).

  #chapter-figure(
    [Módulos y dependencias de la biblioteca de migración],
    image("figures/diagrams/modulos-y-dependencias.svg", width: 84%, alt: "El proxy usa la API del núcleo de coordinación, que depende del transporte Unix, los adaptadores TLS y HTTP y el módulo de observabilidad."),
    target: label("modulos-dependencias"),
  )

  #heading-level-2("2.4", "Diseño detallado")
  #heading-level-3("2.4.1", "Estado y formato de intercambio")

  Se definió una captura lógica de cada comunicación, en lugar de copiar directamente su memoria. El formato incluyó un identificador de migración, la versión del esquema, los identificadores de los adaptadores y las longitudes de sus bloques. Se asignó a cada descriptor un papel explícito: conexión con el cliente o con el servidor. También se incluyeron la asociación entre ambas conexiones y la configuración necesaria para continuar el intercambio ya iniciado.

  El bloque TLS se destinó al contexto negociado, los secretos de tráfico, los contadores por dirección y los datos pendientes. Se exigió conservar el avance de los registros y de los mensajes posteriores al establecimiento, incluidas las actualizaciones de claves. La especificación TLS 1.3 sustentó estos requisitos @rfc8446. Los bytes cifrados ya generados pero aún no enviados se conservaron con su desplazamiento, para continuar su envío sin volver a cifrar el mismo contenido.

  El bloque HTTP incluyó la fase de análisis, la delimitación del cuerpo, el progreso de lectura y escritura y los búferes pendientes. Para la codificación por fragmentos, se contemplaron el fragmento actual y los campos finales. Se tomó RFC 9112 como referencia para delimitar los mensajes y conservar la persistencia @rfc9112. El estado del #emph[proxy] completó esa información con la solicitud activa y su respuesta asociada.

  Se estableció que el receptor validara versiones, tamaños y presencia de ambos descriptores antes de aceptar la captura. No se admitió interpretar un formato desconocido ni copiar punteros, tareas del entorno de ejecución o estructuras criptográficas opacas. Las versiones compatibles debían compartir un esquema o disponer de una conversión explícita. La configuración nueva se reservó para comunicaciones nuevas cuando su aplicación pudiera alterar un intercambio ya iniciado.

  #heading-level-3("2.4.2", "Coordinación del traspaso")

  Se diseñó una secuencia con preparación, restauración y activación. Su condición central fue mantener un solo proceso autorizado para leer o escribir cada comunicación. El envío de descriptores no se trató como una cesión automática de esa autorización.

  + *Preparación.* Se previó iniciar el proceso nuevo, comprobar su compatibilidad y acordar la migración. La recepción de conexiones nuevas se coordinó mediante el recurso de escucha, separadamente de las comunicaciones aceptadas.
  + *Pausa y captura.* Se dispuso detener nuevas operaciones del par y esperar a que las operaciones en curso devolvieran su progreso. El punto seguro exigió que ninguna tarea pudiera modificar el estado capturado. No exigió terminar el cuerpo HTTP ni vaciar sus búferes.
  + *Transferencia y restauración.* Se planteó enviar ambos descriptores y la captura bajo un mismo identificador. El proceso nuevo debía reconstruir los adaptadores y confirmar que el par estaba preparado, todavía sin ejecutar entrada o salida.
  + *Activación.* Tras esa confirmación, se dispuso que el proceso anterior renunciara a reanudar el par y enviara la orden de activación. El nuevo proceso debía continuar una sola vez y confirmar su activación. Después, el anterior podía liberar sus referencias locales.
  + *Retiro.* Se condicionó la salida del proceso anterior a la resolución de todas sus comunicaciones. Los pares rechazados permanecieron como responsabilidad del proceso anterior y debían impedir declarar completada la actualización.

  Antes de autorizar la activación, se permitió cancelar el traspaso y reanudar el origen tras confirmar que el receptor descartó su copia. Después de enviar la autorización, se prohibió reanudar automáticamente por un tiempo de espera agotado. La ausencia de respuesta podía significar que el proceso nuevo ya estuviera atendiendo la conexión. Se previó consultar el estado por identificador y registrar los casos irresueltos como transferencias incompletas. Este tratamiento no pretendió ofrecer recuperación ante fallos abruptos.

  Se distinguió liberar una referencia local de cerrar la comunicación con `shutdown`, operación que no se incluyó en el traspaso normal. Asimismo, se exigió reconstruir el registro de los descriptores en el entorno de ejecución del receptor y conservar exactamente los desplazamientos de las escrituras parciales.

  La @secuencia-migracion muestra un traspaso exitoso durante el envío de un cuerpo HTTP. El nuevo proceso restaura el par en pausa y continúa el reenvío tras recibir la autorización. El cliente y el servidor conservan sus conexiones TCP y sus sesiones TLS.

  #chapter-figure(
    [Secuencia de migración durante el envío de un cuerpo HTTP],
    image("figures/diagrams/secuencia-migracion.svg", width: 96%, alt: "El proxy anterior reenvía parte del cuerpo HTTP, pausa el par y transfiere los descriptores y el estado. El proxy nuevo restaura el par, recibe la autorización y reenvía el resto."),
    note: [Los procesos intercambian los mensajes de control, los descriptores y el estado por el canal Unix.],
    target: label("secuencia-migracion"),
  )

  #heading-level-3("2.4.3", "Recursos y validación de dependencias")

  Se propusieron Tokio para la ejecución asíncrona @tokio-runtime, las interfaces Unix de `nix` o `libc` para el transporte y Serde con un formato binario versionado para la captura @serde. Para los protocolos se tomaron rustls y Hyper como candidatos iniciales. Su incorporación quedó sujeta a demostrar que sus adaptaciones podían exportar e importar el estado requerido en ambos lados del #emph[proxy].

  La extracción de secretos de rustls se evaluó como una interfaz parcial, orientada a configurar kTLS @rustls-secrets. También se consideró mantener la capa de registros en kTLS, pero su documentación conserva responsabilidades de control en espacio de usuario, como la actualización de claves @kernel-tls. Por ello, se priorizó estudiar una adaptación explícita de rustls antes de introducir esa distribución adicional del estado.

  La prueba de viabilidad se definió sobre un intercambio con datos pendientes: pausar, exportar, reconstruir en otro proceso y continuar. Debía cubrir los papeles de cliente y servidor TLS, así como mensajes HTTP incompletos. Si una interfaz pública resultaba insuficiente, se previó documentar una modificación acotada de la dependencia. Las versiones y cambios concretos debían fijarse tras esa prueba. La aceptación exigió migrar mensajes incompletos.

  #heading-level-3("2.4.4", "Panel de observabilidad")

  La biblioteca registrará eventos del traspaso y ofrecerá un panel HTML opcional. Al habilitar la observabilidad en el #emph[proxy] de demostración, la biblioteca iniciará un servidor HTTP local para mostrar el panel. La instrumentación registrará el identificador y la hora de cada intento, los identificadores de proceso (PID) de las dos instancias locales del #emph[proxy] y el resultado. El #emph[proxy] de demostración podrá asociar cada intento con el identificador del servidor HTTP que ya atiende la conexión. Los registros se limitarán a metadatos operativos y excluirán los secretos TLS y los cuerpos HTTP.

  - *Resumen.* Presentará el promedio de duración de las migraciones exitosas, contado desde la solicitud hasta la confirmación de activación. Mostrará los totales de intentos exitosos y fallidos y la proporción de éxitos, rechazos y traspasos incompletos. El panel expresará el consumo adicional de CPU como un aumento relativo en porcentaje y el de memoria residente como una diferencia en MiB. Ambos incrementos se calcularán respecto a la ejecución sin actualización bajo carga equivalente.
  - *Logs.* Mostrará una fila por intento, con hora, identificador, PID del proceso anterior, PID del proceso nuevo, duración hasta la activación cuando se haya confirmado, resultado y detalle operativo. El registro podrá ordenarse por hora en ambos sentidos y filtrarse por hora o por resultado. La vista indica que el proceso anterior solo se retira cuando se confirma que el nuevo asumió todas las conexiones previstas.
  - *Servidores.* Agrupará los intentos, los éxitos y los fallos por el servidor HTTP que ya atiende la conexión #emph[proxy]–servidor. Mostrará la tasa de éxito y la duración media de los intentos exitosos por servidor. El traspaso de las conexiones ocurre entre los dos procesos del #emph[proxy] en el mismo equipo Linux.

  Las figuras #ref(<panel-resumen>, supplement: none), #ref(<panel-logs>, supplement: none) y #ref(<panel-servidores>, supplement: none) muestran las tres vistas principales del prototipo en Figma con datos de ejemplo.#footnote[#link("https://www.figma.com/design/h3bnz9BI44GdkIczqj9SYo?node-id=4-38")[Prototipo del panel de observabilidad en Figma.]] El #link(<anexo-prototipo>)[Anexo C] reúne las vistas principales y documenta el acceso al registro de fallos. Las mediciones se obtendrán de las ejecuciones experimentales descritas en la sección 2.5.

  #chapter-figure(
    [Resumen de las migraciones],
    image("figures/panel/resumen.png", width: 100%, alt: "Resumen con duración media, totales de intentos, distribución porcentual y consumo adicional de CPU y memoria."),
    target: label("panel-resumen"),
  )

  #chapter-figure(
    [Registro de migraciones],
    image("figures/panel/logs.png", width: 100%, alt: "Registro con identificadores de intento, PID de ambos procesos, orden y filtro por hora y condición para el retiro del proceso anterior."),
    target: label("panel-logs"),
  )

  #chapter-figure(
    [Resultados por servidor HTTP],
    image("figures/panel/servidores.png", width: 100%, alt: "Vista Servidores del prototipo con el número de intentos y sus resultados por servidor HTTP."),
    target: label("panel-servidores"),
  )

  #heading-level-2("2.5", "Implementación y evaluación previstas")

  Se planificó implementar primero la transferencia de pares TCP, después la captura TLS y finalmente la conservación del procesamiento HTTP. Cada etapa se condicionó a verificar continuidad e integridad antes de añadir la siguiente. La entrega se definió como biblioteca Rust, adaptadores documentados, #emph[proxy] de demostración y herramientas para reproducir las pruebas.

  El experimento se diseñó con tres modalidades del mismo #emph[proxy]: sin actualización, actualización mediante drenaje y actualización mediante migración. Se fijó como intervención el mecanismo de actualización. Se propuso mantener constantes la máquina, las versiones, el contenido, la concurrencia y las condiciones de red. El cliente y el servidor debían ejecutar la misma carga en las tres modalidades, con reintentos automáticos desactivados para detectar interrupciones.

  Se seleccionaron cargas y descargas prolongadas, conexiones persistentes y cuerpos con ambas formas de delimitación. Se incluyeron escrituras parciales, receptores lentos y distintos volúmenes pendientes. El disparo del traspaso se vinculó a un progreso conocido de la transferencia para comprobar que ocurriera antes de completar el cuerpo. También se previeron rechazos por incompatibilidad y errores anteriores a la activación.

  Para cada escenario se planificaron repeticiones independientes y un orden alternado de las modalidades. Una prueba piloto debía fijar los niveles de concurrencia, las duraciones y el número de repeticiones antes de la evaluación definitiva. Se dispuso registrar esos parámetros, el equipo, el sistema operativo y las versiones utilizadas, sin seleccionar únicamente ejecuciones exitosas.

  - *Continuidad e integridad.* Se previó comparar el contenido, el orden y los identificadores de solicitud en ambos extremos. Se exigió verificar la ausencia de nuevas conexiones TCP o de un nuevo establecimiento TLS causado por la migración.
  - *Tiempo de migración.* Se definió como el intervalo desde la solicitud hasta la confirmación de activación. Se separaron la espera del punto seguro y la transferencia/restauración. Se añadió el tiempo hasta el retiro efectivo del proceso anterior.
  - *Pausa observable.* Se definió como el intervalo sin progreso de la aplicación alrededor del traspaso. Se previó medirlo en cada extremo con reloj monotónico y contrastarlo con la ejecución sin actualización.
  - *Costo operativo.* Se propuso medir rendimiento, latencia, consumo de CPU, memoria y tamaño de la captura. Se incluyó el registro de los cambios necesarios para integrar los adaptadores.

  La comparación con drenaje se destinó a evaluar el tiempo de retiro. La ejecución sin actualización se destinó a estimar la sobrecarga. Se propuso informar medianas, percentiles y dispersión, junto con transferencias exitosas, rechazadas e incompletas. La interpretación se delimitó al entorno evaluado, sin anticipar umbrales de rendimiento ni extrapolar los resultados a otros #emph[proxies].

  #heading-level-2("2.6", "Pruebas de usuario del panel")

  El operador del #emph[proxy] es el usuario principal del panel. Lo consulta para revisar el traspaso antes de retirar el proceso anterior (HU-05). El investigador revisa la duración y el consumo de recursos (HU-07). El desarrollador puede usar el panel para revisar una integración (HU-01). El usuario del servicio se beneficia de la continuidad de sus conexiones (HU-04).

  Las pruebas se centraron en el perfil del operador del #emph[proxy]. Las tareas se diseñaron para ese perfil, que requiere experiencia en la operación de servicios en Linux y en la lectura de registros.

  Las tareas evaluaron si los participantes podían explicar el resultado de la migración, interpretar el costo en CPU y memoria, investigar un intento fallido y distinguir el servidor HTTP de los procesos entre los que ocurre el traspaso. La guía y las fichas de registro se incluyen en el #link(<anexo-pruebas>)[Anexo B].

  #heading-level-2("2.7", "Resultados de las pruebas de usuario")

  Se realizaron seis pruebas con el prototipo de Figma. Los seis participantes resolvieron correctamente las tareas de Resumen, Recursos y Servidores. Los resultados individuales se recogen en el #link(<anexo-pruebas>)[Anexo B].

  La decisión sobre el retiro del proceso anterior fue el punto de mayor dificultad. Tres participantes coincidieron con el criterio de mantener el proceso ante un rechazo o una confirmación pendiente. Una persona dudó ante el intento incompleto y otra solo indicó qué haría ante el rechazo. Una persona interpretó los dos registros como un mismo intento porque compartían los PID. En el registro, cada intento tiene su propio identificador, aunque los procesos sean los mismos.

  La prioridad es destacar el identificador de cada intento e indicar que el retiro requiere confirmar que el proceso nuevo asumió todas las conexiones previstas. En Recursos, un participante preguntó por el significado de la línea base y de la abreviatura pp. El panel puede identificar la línea base como la ejecución sin actualización y escribir puntos porcentuales junto al valor de CPU. También se propuso mostrar porcentajes en las barras de Resumen, simplificar el acceso a Logs desde Servidores y permitir ordenar y filtrar los registros por columna. Un participante valoró que el panel muestra una cantidad manejable de información.
]
