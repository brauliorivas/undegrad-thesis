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

  #heading-level-3("2.4.3", "Recursos y validación de dependencias")

  Se propusieron Tokio para la ejecución asíncrona @tokio-runtime, las interfaces Unix de `nix` o `libc` para el transporte y Serde con un formato binario versionado para la captura @serde. Para los protocolos se tomaron rustls y Hyper como candidatos iniciales. Su incorporación quedó sujeta a demostrar que sus adaptaciones podían exportar e importar el estado requerido en ambos lados del #emph[proxy].

  La extracción de secretos de rustls se evaluó como una interfaz parcial, orientada a configurar kTLS @rustls-secrets. También se consideró mantener la capa de registros en kTLS, pero su documentación conserva responsabilidades de control en espacio de usuario, como la actualización de claves @kernel-tls. Por ello, se priorizó estudiar una adaptación explícita de rustls antes de introducir esa distribución adicional del estado.

  La prueba de viabilidad se definió sobre un intercambio con datos pendientes: pausar, exportar, reconstruir en otro proceso y continuar. Debía cubrir los papeles de cliente y servidor TLS, así como mensajes HTTP incompletos. Si una interfaz pública resultaba insuficiente, se previó documentar una modificación acotada de la dependencia. Las versiones y cambios concretos debían fijarse tras esa prueba. La aceptación exigió migrar mensajes incompletos.

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
]
