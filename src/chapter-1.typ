#import "style.typ": heading-level-1, heading-level-2, heading-level-3
#import "chapter-visuals.typ": chapter-figure, chapter-table, ruled-table

#let chapter-one() = [
  #heading-level-1("CAPÍTULO 1")

  #heading-level-2("1.1", "Introducción")

  Los servicios digitales necesitan corregir vulnerabilidades, incorporar funciones y modificar configuraciones mientras atienden a sus usuarios. Estas tareas suelen exigir el reemplazo de procesos que mantienen comunicaciones activas. En esa infraestructura, los #emph[proxies] balanceadores de carga son programas intermediarios que reciben solicitudes de clientes y las distribuyen entre servidores. Su actualización afecta tanto la recepción de tráfico nuevo como la continuidad de las comunicaciones que ya atienden. Surge así el problema de retirar la versión anterior sin cerrar esas comunicaciones ni esperar a que terminen.

  La duración de esas comunicaciones condiciona el mantenimiento. Cloudflare documentó que Oxy, su plataforma para construir #emph[proxies] en Rust, atiende conexiones prolongadas destinadas a respaldos, actualizaciones en tiempo real y sesiones remotas. El artículo explica que esperar un periodo de menor actividad no resuelve el problema cuando una corrección de seguridad requiere desplegarse de inmediato @cloudflare-oxy.

  La necesidad de actualizar con rapidez también aparece en los datos de seguridad. Mandiant analizó 41 vulnerabilidades divulgadas en 2023 cuya primera explotación ocurrió después de estar disponible un parche: el 29 % se explotó en una semana y el 56 %, en un mes @mandiant-tte. Estos datos respaldan la importancia de desplegar correcciones oportunamente, aunque no miden el riesgo específico de los #emph[proxies].

  Una práctica habitual consiste en iniciar la nueva versión y mantener la anterior hasta que complete sus comunicaciones, procedimiento denominado drenaje. Así se conserva el servicio, pero el retiro del código anterior depende del trabajo pendiente. La migración modifica esa dependencia al trasladar la atención de las conexiones a la nueva versión. La @actualizacion representa ambos procedimientos y distingue el inicio de la actualización del retiro efectivo del proceso anterior.

  #chapter-figure(
    [Drenaje y migración durante una actualización],
    image("figures/actualizacion.svg", width: 100%),
    note: [Esquema conceptual sin escala temporal. La migración incluye la espera hasta una condición de captura consistente y el traspaso; no implica una pausa nula.],
    target: label("actualizacion"),
  )

  El proyecto integrador se orienta a una biblioteca reutilizable en Rust que transfiera conexiones activas y su estado entre procesos de una misma máquina Linux, incluso durante mensajes incompletos. Comprende comunicaciones protegidas con TLS 1.3, protocolo de seguridad para cifrar el intercambio, y HTTP/1.1, protocolo que organiza solicitudes y respuestas. La propuesta integra el componente en el código de un #emph[proxy] y requiere cooperación de las implementaciones de esos protocolos.

  Su desarrollo aplica contenidos de Sistemas Operativos, Seguridad de la Información, Sistemas Distribuidos y Computación en la Nube: administración de recursos, coordinación entre procesos, protección del estado criptográfico y evaluación bajo concurrencia. Para los desarrolladores de #emph[proxies], aporta una interfaz de integración y adaptaciones documentadas; para los equipos de operación, evidencia sobre continuidad y tiempo de mantenimiento. Su utilidad potencial consiste en actualizar infraestructura compartida sin exigir reconexiones a los usuarios de las comunicaciones transferidas.

  El capítulo 2 presentará las alternativas, el diseño y la metodología de implementación y evaluación. El capítulo 3 analizará continuidad, costos y esfuerzo de integración. El capítulo 4 expondrá las conclusiones por objetivo y las recomendaciones.

  #heading-level-2("1.2", "Descripción del problema")

  El problema abordado es la falta de un componente reutilizable en Rust con tres propiedades: transfiere localmente las conexiones aceptadas de un #emph[proxy]; conserva su estado TLS 1.3 y HTTP/1.1 en ambos lados durante mensajes incompletos; y ofrece una interfaz independiente de un #emph[proxy] particular. Existen mecanismos de migración, pero su adopción depende de plataformas, pilas de red o adaptaciones específicas. Por ello, el problema comprende definir qué estado debe exponer la aplicación, cómo coordinar el traspaso y bajo qué condiciones puede continuar la comunicación.

  El escenario principal es una actualización planificada entre dos procesos cooperantes en la misma máquina Linux. El #emph[proxy] mantiene dos conexiones independientes del protocolo de control de transmisión (TCP): cliente–#emph[proxy] y #emph[proxy]–servidor de destino. En ambas utiliza TLS 1.3 y HTTP/1.1, actuando como servidor frente al cliente y como cliente frente al destino. La transferencia comprende las dos conexiones, sus datos pendientes y la asociación que permite encaminar cada solicitud y respuesta, como representa la @estado-conexiones.

  Un punto de integración es el lugar del código donde el #emph[proxy] invoca la biblioteca para registrar, transferir o restaurar una conexión. Un punto seguro es una condición de ejecución en la que puede capturarse un estado consistente, sin operaciones de entrada y salida ni tareas concurrentes que lo modifiquen. La captura se coordina entre operaciones del programa y no exige terminar el mensaje HTTP ni vaciar todos los búferes: los datos pendientes y el progreso del procesamiento forman parte del estado transferido. Esta condición se refiere a la aplicación; el #emph[kernel] sigue gestionando los paquetes TCP.

  #chapter-figure(
    [Conexiones y estado que conserva el proxy],
    image("figures/estado-conexiones.svg", width: 88%),
    note: [Los contextos TLS son independientes. Linux conserva los recursos TCP; el proceso conserva el estado de protocolos y la asociación entre conexiones.],
    target: label("estado-conexiones"),
  )

  Los puntos seguros requeridos comprenden conexiones persistentes entre intercambios y la recepción o el envío de cuerpos HTTP aún incompletos. La validación incluye cargas y descargas con longitud conocida y con codificación por fragmentos, con un intercambio activo por par de conexiones. El proceso nuevo debe continuar desde el progreso registrado, sin repetir la solicitud ni esperar al final del cuerpo. Quedan fuera la migración durante el establecimiento TLS, las solicitudes HTTP canalizadas (#emph[pipelining]) y los cambios de protocolo, como WebSocket.

  El alcance principal comprende el núcleo de coordinación y transferencia local, los adaptadores de TLS 1.3 y HTTP/1.1 para ambos lados y un #emph[proxy] sencillo de demostración. El núcleo administra el traspaso y la confirmación de restauración; los adaptadores conectan la interfaz común con cada implementación de protocolos y exponen su estado específico. Solo se admite compatibilidad con las bibliotecas adaptadas y con las versiones cuyo formato de estado se comprueba. El capítulo 2 seleccionará las dependencias mediante una prueba de exportación y restauración, y desarrollará el traspaso conjunto de ambas conexiones como alcance obligatorio. La validación utiliza un solo #emph[proxy]; los resultados no establecen aplicabilidad a otros.

  HTTP/2 constituye una extensión opcional. Quedan fuera el traslado entre máquinas, la recuperación ante fallos abruptos, las aplicaciones sin cooperación y QUIC/HTTP/3. Los usuarios previstos son desarrolladores y operadores de infraestructura digital; el proyecto no tiene una organización cliente identificada.

  Se acepta una transferencia si ambas conexiones continúan, conservan contenido, orden y asociación, y el proceso anterior se retira tras la confirmación del nuevo. Las pruebas provocan el traspaso antes de completar cargas y descargas, incluidas escrituras parciales y datos pendientes; verifican el contenido recibido y la ausencia de nuevas conexiones y de un nuevo establecimiento TLS. Una pausa temporal se mide como latencia, sin confundirla con una reconexión.

  La evaluación compara el mismo #emph[proxy] con migración, con drenaje y sin actualización: el drenaje contrasta el tiempo de retiro y la ejecución sin actualización mide la sobrecarga. La efectividad corresponde a continuidad e integridad; los límites operativos se caracterizan mediante tiempos, recursos, concurrencia y volumen pendiente. Se registran rechazos y transferencias incompletas, sin excluirlos del resultado. Las variables se comparan bajo las mismas cargas, sin anticipar umbrales numéricos. La @requisitos reúne las condiciones y variables que hacen observable el problema.

  #chapter-table(
    [Requisitos, restricciones y variables de evaluación],
    ruled-table(
      columns: (1.1fr, 1.45fr, 3.45fr),
      table.header([*Tipo*], [*Elemento*], [*Condición o medición*]),
      [Requisito], [Continuidad], [Ambas conexiones continúan sin reconexión ni un nuevo establecimiento de TLS causado por el traspaso.],
      [Requisito], [Integridad], [Contenido y orden conservados en ambas direcciones, sin pérdida, duplicación ni alteración de los datos entregados.],
      [Requisito], [Asociación], [Se conserva la asociación entre las dos conexiones de cada comunicación.],
      [Requisito], [Mensaje en curso], [El traspaso se completa durante la recepción o el envío de un cuerpo HTTP, conservando su progreso y los búferes pendientes.],
      [Requisito], [Retiro], [El proceso nuevo confirma la restauración antes de que el proceso anterior se retire.],
      [Restricción], [Entorno y estado], [Linux local, procesos cooperantes, TLS establecido, puntos seguros y versiones compatibles. Acceso restringido al canal y a los secretos transferidos.],
      [Variable], [Tiempos], [Espera hasta el punto seguro, transferencia, pausa visible en cada extremo y retiro del proceso anterior.],
      [Variable], [Recursos y carga], [Uso de procesador (CPU) y memoria adicional; concurrencia, duración de conexiones y volumen de datos pendientes.],
      [Variable], [Integración], [Cambios en el #emph[proxy], tamaño de las adaptaciones y actividades necesarias para integrarlas.],
    ),
    target: label("requisitos"),
  )

  #heading-level-2("1.3", "Justificación del problema")

  Resolver este problema permite actualizar el #emph[proxy] sin supeditar el retiro de la versión anterior a la duración de las comunicaciones. Cloudflare documenta esa dependencia al drenar conexiones prolongadas @cloudflare-oxy; GitHub describe cómo conserva la recepción de tráfico durante los reemplazos de HAProxy, mientras las conexiones establecidas permanecen en los procesos anteriores @github-multibinder. Para los operadores, reducir esa espera facilita retirar código que requiere correcciones y controlar la coexistencia de versiones. Para los usuarios, conservar la comunicación evita reiniciar una transferencia por el cambio del intermediario.

  Los antecedentes resuelven partes del problema mediante herencia de escucha, captura de procesos o migración de conexiones @cloudflare-ecdysis @criu @mosn-upgrade @capybara. Sin embargo, su integración debe considerar conjuntamente los dos lados del #emph[proxy], el estado TLS/HTTP y la restauración entre versiones compatibles sobre #emph[sockets] de Linux. La @comparacion sintetiza esa adaptación pendiente respecto al alcance del proyecto; sus limitaciones no se presentan como imposibilidad de extender los sistemas existentes.

  // La comparación del proyecto se ubica aquí, fuera del marco teórico.
  #chapter-table(
    [Mecanismos existentes y adaptación requerida para el proyecto],
    ruled-table(
      columns: (1.15fr, 2.15fr, 3.2fr),
      table.header([*Alternativa*], [*Qué proporciona*], [*Adaptación o validación requerida*]),
      [Ecdysis @cloudflare-ecdysis], [Hereda recursos de escucha; las conexiones aceptadas permanecen en el proceso anterior.], [Trasladar también las conexiones aceptadas y su estado.],
      [Hot Restart Proxy @hot-restart-proxy], [Transfiere pares TCP entre procesos Linux.], [Añadir restauración TLS y HTTP, ausente en la demostración.],
      [CRIU / libsoccr @criu @libsoccr], [Captura procesos y memoria; libsoccr conserva TCP.], [Restaurar el estado en otra versión del programa; libsoccr no trata TLS/HTTP.],
      [SockMi @sockmi-ssl], [Exporta conexiones cifradas con OpenSSL y un módulo Linux.], [Adaptar a TLS 1.3 y validar HTTP; sus pruebas usan TLS anterior y el mismo programa.],
      [MOSN @mosn-upgrade], [Migra la conexión del cliente, búferes y TLS; abre otra hacia el servidor.], [Conservar también la conexión del servidor y extraer la coordinación del #emph[proxy] Go.],
      [PRISM @prism], [Transfiere conexiones y TLS/HTTP a servidores con red programable.], [Adaptar la API al reemplazo local de versiones y al traspaso de ambos lados.],
      [XO @xo], [Descarga conexiones y TLS/HTTP desde un balanceador mediante eBPF.], [Integrar la actualización local preservando ambas conexiones y su asociación.],
      [Capybara @capybara], [Migra TCP, TLS con TLSe y solicitudes HTTP parciales; usa Demikernel.], [Adaptar a #emph[sockets] de Linux y validar ambos lados entre versiones compatibles.],
    ),
    note: [La última columna es un análisis del autor respecto al alcance propuesto, a partir de las fuentes citadas.],
    target: label("comparacion"),
  )

  El aporte consiste en una biblioteca que reúna la coordinación del traspaso local, los adaptadores TLS/HTTP y la confirmación de restauración antes de retirar el proceso anterior. Se elige Rust por su control de recursos mediante reglas de propiedad comprobadas por el compilador @rust-ownership, adecuado para gestionar conexiones y búferes. La interfaz común permitirá reutilizar la coordinación, aunque cada implementación de protocolos necesite adaptación. La evaluación aportará evidencia sobre continuidad durante mensajes incompletos, tiempo de retiro frente al drenaje y sobrecarga introducida.

  #heading-level-2("1.4", "Objetivos")

  #heading-level-3("1.4.1", "Objetivo general")

  Desarrollar una biblioteca en Rust que migre conexiones TCP activas entre procesos de un #emph[proxy] en la misma máquina, preservando el estado TLS/HTTP y manteniendo la continuidad de la comunicación.

  #heading-level-3("1.4.2", "Objetivos específicos")

  + Identificar el estado de los protocolos de comunicación que debe preservarse para garantizar la continuidad de las conexiones durante su migración entre procesos.
  + Diseñar la arquitectura de la biblioteca y el formato de intercambio de estado entre las instancias de origen y destino del #emph[proxy].
  + Implementar la transferencia del #emph[socket] TCP y los adaptadores necesarios para la migración del estado TLS y HTTP en un #emph[proxy] de demostración.
  + Evaluar el prototipo mediante pruebas de continuidad de conexiones, tiempo de migración y sobrecarga durante una actualización del #emph[proxy].

  #heading-level-2("1.5", "Marco teórico")

  La literatura relaciona la actualización de intermediarios con la conservación de estado en varias capas. Primero se presentan el balanceo de carga y el reemplazo de procesos; después, el estado TCP, TLS y HTTP; finalmente, los mecanismos de migración y transferencia en funciones de red.

  #heading-level-3("1.5.1", "Proxies y actualización de procesos")

  Un balanceador de carga distribuye comunicaciones entre servidores. En capa 4 toma decisiones con información de red y transporte, como direcciones y puertos; en capa 7 interpreta mensajes de aplicación, por ejemplo cabeceras y rutas HTTP @haproxy-intro. Un #emph[proxy] que termina conexiones mantiene una comunicación con el cliente y otra con el servidor de destino, con procesamiento independiente en cada lado @haproxy-management. En un intermediario HTTP, las solicitudes y respuestas se analizan y reenvían conforme a las reglas de delimitación y persistencia de HTTP/1.1 @rfc9112. Esta estructura sitúa el estado de transporte y de aplicación en el recorrido de una misma operación.

  NGINX, HAProxy y Envoy permiten reemplazar procesos conservando la recepción de tráfico: el proceso anterior atiende las conexiones existentes hasta completarlas o alcanzar el plazo de cierre @nginx-control @haproxy-management @envoy-hot-restart. Envoy indica expresamente que no las transfiere a la nueva instancia. Estos procedimientos constituyen el drenaje usado como referencia de evaluación. Multibinder @github-multibinder, ecdysis @cloudflare-ecdysis y listenfd @listenfd facilitan la herencia de recursos de escucha, sin trasladar el estado de las conexiones ya aceptadas.

  #heading-level-3("1.5.2", "Estado de transporte y protocolos de aplicación")

  TCP proporciona un flujo de bytes fiable y ordenado mediante números de secuencia, confirmaciones, ventanas y retransmisiones @rfc9293. En Linux, ese estado pertenece a un #emph[socket] del #emph[kernel]; el descriptor es la referencia mediante la cual un proceso accede al recurso. Los #emph[sockets] de dominio Unix permiten pasar descriptores con `SCM_RIGHTS`, mecanismo que entrega al receptor una referencia al mismo recurso abierto @linux-unix. Por tanto, un traspaso local puede conservar el #emph[socket] existente sin reconstruir la conexión TCP; los datos que la aplicación ya extrajo del #emph[kernel] requieren tratamiento separado.

  TLS 1.3 protege los registros con secretos de tráfico y números de secuencia independientes para envío y recepción. Su estado incluye la fase del protocolo, las claves vigentes y los registros pendientes; una actualización de claves modifica parte de ese contexto. La reanudación TLS establece una nueva comunicación a partir de información previa, por lo que no sustituye la conservación del contexto de una conexión activa @rfc8446. En un #emph[proxy] con TLS en ambos lados existen dos contextos independientes, correspondientes a sus papeles de servidor y cliente.

  HTTP/1.1 delimita mensajes mediante cabeceras y reglas como la longitud del contenido o la codificación por fragmentos. Una conexión persistente puede transportar varios intercambios; conservarla requiere conocer el avance del mensaje y los bytes pendientes de análisis o envío @rfc9112. El estado del #emph[proxy] también comprende la relación entre una solicitud recibida y la respuesta del destino. Así, el descriptor y las claves no describen por sí solos el avance del procesamiento.

  Las interfaces de bibliotecas concretas exponen partes diferentes de ese estado. La biblioteca TLS rustls documenta la extracción de secretos y contadores para configurar kTLS, mecanismo de Linux que procesa la capa de registros TLS @rustls-secrets @kernel-tls. La biblioteca HTTP Hyper permite recuperar el recurso de entrada y salida con `into_parts`, pero exige que el procesamiento haya terminado para no dejar bytes HTTP sin enviar @hyper-http1. La documentación establece condiciones específicas para estas operaciones parciales, sin describir en esas interfaces una restauración completa entre procesos.

  #heading-level-3("1.5.3", "Migración de conexiones y actualización de estado")

  Snoeren, Andersen y Balakrishnan estudiaron en 2001 la recuperación mediante migración de conexiones, combinando soporte de transporte con sincronización de estado de aplicación @tcp-failover. SockMi abordó posteriormente conexiones cifradas mediante un módulo de Linux, un servicio de migración y una biblioteca que exportaba estructuras de OpenSSL @sockmi-ssl. Sus pruebas empleaban versiones anteriores a TLS 1.3 y restauraban la ejecución con el mismo #emph[software].

  CRIU (#emph[Checkpoint/Restore In Userspace]) es una herramienta que captura y restaura procesos Linux, incluidos sus recursos y memoria; también ofrece libsoccr como biblioteca para conservar conexiones TCP @criu. `TCP_REPAIR` es el modo de Linux que permite detener el procesamiento normal de una conexión y consultar o restaurar su estado, utilizado por esa biblioteca @libsoccr. COAT combina CRIU, contenedores y una red virtual para trasladar ejecuciones en el borde de la red @coat. Estos mecanismos restauran el estado capturado, sin definir automáticamente su conversión para otra versión del programa.

  La actualización dinámica estudia esa conversión. Kitsune permite actualizar programas en C mediante puntos indicados por el desarrollador y transformaciones de datos @kitsune. MOSN documenta una actualización local que pasa la conexión del cliente, sus búferes y el estado TLS mediante un canal Unix; la nueva instancia establece otra conexión con el servidor de destino @mosn-upgrade. Como antecedente en Rust, el proyecto de demostración Hot Restart Proxy pasa pares de conexiones TCP entre procesos, aunque la demostración no incorpora estado TLS ni análisis HTTP @hot-restart-proxy.

  #heading-level-3("1.5.4", "Transferencia en funciones de red y balanceo de carga")

  OpenNF estudia la transferencia coordinada de estado en funciones de red @opennf. HA/TCP utiliza réplicas sincronizadas y una pila FreeBSD modificada en espacio de usuario para cambiar el responsable de una conexión @ha-tcp. PRISM transfiere conexiones y estado TLS/HTTP mediante una red programable @prism; XO utiliza eBPF, infraestructura de Linux para ejecutar programas verificados, en la descarga de conexiones hacia servidores @xo.

  Capybara implementa exportación e importación del estado de aplicación sobre Demikernel, una pila de red en espacio de usuario, y un conmutador programable. Su servidor HTTP mínimo transfiere el búfer de una solicitud parcial; la integración TLS utiliza TLSe, que serializa contadores y registros pendientes. El sistema requiere que la aplicación proporcione un estado consistente. En ese entorno, reporta menos de 15 µs con el estado TCP básico y menos de 60 µs con 128 KB de estado TLS @capybara. Son mediciones de ese prototipo, no umbrales aplicables a otras implementaciones.

  La migración de conexión de QUIC tiene otro significado: permite cambiar direcciones o rutas de una comunicación y no especifica cómo transferir la memoria de un #emph[proxy] entre versiones @rfc9000.
]
