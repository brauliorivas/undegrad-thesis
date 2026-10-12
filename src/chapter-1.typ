#import "style.typ": heading-level-1, heading-level-2, heading-level-3
#import "chapter-visuals.typ": chapter-figure, chapter-table, ruled-table

#let chapter-one() = [
  #heading-level-1("CAPÍTULO 1")

  #heading-level-2("1.1", "Introducción")

  Los servicios digitales necesitan corregir vulnerabilidades, incorporar funciones y modificar configuraciones mientras atienden a sus usuarios. Estas tareas suelen exigir el reemplazo de procesos que mantienen comunicaciones activas. En esa infraestructura, los #emph[proxies] balanceadores de carga son programas intermediarios que reciben solicitudes de clientes y las distribuyen entre servidores. Su actualización afecta tanto la recepción de tráfico nuevo como la continuidad de las comunicaciones que ya atienden.

  La duración de esas comunicaciones condiciona el mantenimiento. Cloudflare documentó que Oxy, su plataforma para construir #emph[proxies] en Rust, atiende conexiones prolongadas destinadas a respaldos, actualizaciones en tiempo real y sesiones remotas. El artículo explica que esperar un periodo de menor actividad no resuelve el problema cuando una corrección de seguridad requiere desplegarse de inmediato @cloudflare-oxy.

  La necesidad de actualizar con rapidez también aparece en los datos de seguridad. Mandiant analizó 41 vulnerabilidades divulgadas en 2023 cuya primera explotación ocurrió después de estar disponible un parche: el 29 % se explotó en una semana y el 56 %, en un mes @mandiant-tte. Estos datos respaldan la importancia de desplegar correcciones oportunamente, aunque no miden el riesgo específico de los #emph[proxies].

  Una práctica habitual consiste en iniciar la nueva versión y mantener la anterior hasta que complete sus comunicaciones, procedimiento denominado drenaje. Así se conserva el servicio, pero el retiro del código anterior depende del trabajo pendiente. La migración modifica esa dependencia al trasladar la atención de las conexiones a la nueva versión. La @actualizacion representa ambos procedimientos y distingue el inicio de la actualización del retiro efectivo del proceso anterior.

  #chapter-figure(
    [Drenaje y migración durante una actualización],
    image("figures/actualizacion.svg", width: 100%),
    note: [Esquema conceptual sin escala temporal. La migración incluye la espera hasta una condición de captura consistente y el traspaso; no implica una pausa nula.],
    target: label("actualizacion"),
  )

  El proyecto integrador se orienta a una biblioteca reutilizable en Rust que transfiera conexiones activas y su estado entre procesos de una misma máquina Linux. Comprende comunicaciones protegidas con TLS 1.3, protocolo de seguridad para cifrar el intercambio, y HTTP/1.1, protocolo que organiza solicitudes y respuestas. La propuesta integra el componente en el código de un #emph[proxy] y requiere cooperación de las implementaciones de esos protocolos.

  Su desarrollo aplica contenidos de Sistemas Operativos, Seguridad de la Información, Sistemas Distribuidos y Computación en la Nube: administración de recursos, coordinación entre procesos, protección del estado criptográfico y evaluación bajo concurrencia. Para los desarrolladores de #emph[proxies], aporta una interfaz de integración y adaptaciones documentadas; para los equipos de operación, evidencia sobre continuidad y tiempo de mantenimiento. Su utilidad potencial consiste en actualizar infraestructura compartida sin exigir reconexiones a los usuarios de las comunicaciones transferidas.

  El capítulo 2 presentará las alternativas, el diseño y la metodología de implementación y evaluación. El capítulo 3 analizará continuidad, costos y esfuerzo de integración. El capítulo 4 expondrá las conclusiones por objetivo y las recomendaciones.

  #heading-level-2("1.2", "Descripción del problema")

  El problema abordado es la falta de un componente reutilizable en Rust con tres propiedades: transfiere localmente las conexiones aceptadas de un #emph[proxy]; conserva su estado TLS 1.3 y HTTP/1.1 en ambos lados; y ofrece una interfaz independiente de un #emph[proxy] particular. Existen mecanismos de migración, pero su adopción depende de plataformas, pilas de red o adaptaciones específicas. Por ello, el problema comprende definir qué estado debe exponer la aplicación, cómo coordinar el traspaso y bajo qué condiciones puede continuar la comunicación.

  El escenario principal es una actualización planificada entre dos procesos cooperantes en la misma máquina Linux. El #emph[proxy] mantiene dos conexiones independientes del protocolo de control de transmisión (TCP): cliente–#emph[proxy] y #emph[proxy]–servidor de destino. En ambas utiliza TLS 1.3 y HTTP/1.1, actuando como servidor frente al cliente y como cliente frente al destino. La transferencia comprende las dos conexiones, sus datos pendientes y la asociación que permite encaminar cada solicitud y respuesta, como representa la @estado-conexiones.

  #chapter-figure(
    [Conexiones y estado que conserva el proxy],
    image("figures/estado-conexiones.svg", width: 88%),
    note: [Los contextos TLS son independientes. Linux conserva los recursos TCP; el proceso conserva el estado de protocolos y la asociación entre conexiones.],
    target: label("estado-conexiones"),
  )

  Un punto de integración es el lugar del código donde el #emph[proxy] invoca la biblioteca para registrar, transferir o restaurar una conexión. Un punto seguro es una condición de ejecución en la que puede capturarse un estado consistente, sin lecturas, escrituras o tareas concurrentes que lo modifiquen. Los adaptadores son componentes que conectan la interfaz de la biblioteca con una implementación concreta de TLS o HTTP. El diseño determina los puntos seguros admitidos y si incluyen mensajes HTTP en curso; la garantía de continuidad se limita a esos estados.

  El alcance principal comprende el núcleo de coordinación y transferencia local, los adaptadores de TLS 1.3 y HTTP/1.1 para ambos lados y un #emph[proxy] sencillo de demostración. El núcleo administra el traspaso y la confirmación de restauración; los adaptadores exponen el estado específico de cada protocolo. Solo se admite compatibilidad con las bibliotecas adaptadas y con las versiones cuyo formato de estado se comprueba. La selección de dependencias depende de una prueba de exportación y restauración de su estado. La validación utiliza un solo #emph[proxy]; los resultados no establecen aplicabilidad a otros.

  HTTP/2 constituye una extensión opcional. Quedan fuera el traslado entre máquinas, la recuperación ante fallos abruptos, las aplicaciones sin cooperación y QUIC/HTTP/3. Los usuarios previstos son desarrolladores y operadores de infraestructura digital; el proyecto no tiene una organización cliente identificada. La @requisitos reúne las condiciones y variables que hacen observable el problema.

  #chapter-table(
    [Requisitos, restricciones y variables de evaluación],
    ruled-table(
      columns: (1.1fr, 1.45fr, 3.45fr),
      table.header([*Tipo*], [*Elemento*], [*Condición o medición*]),
      [Requisito], [Continuidad], [Ambas conexiones continúan sin reconexión ni un nuevo establecimiento de TLS causado por el traspaso.],
      [Requisito], [Integridad], [Contenido y orden conservados en ambas direcciones, sin pérdida, duplicación ni alteración de los datos entregados.],
      [Requisito], [Asociación], [Se conserva la asociación entre las dos conexiones de cada comunicación.],
      [Requisito], [Retiro], [El proceso nuevo confirma la restauración antes de que el proceso anterior se retire.],
      [Restricción], [Entorno y estado], [Linux local, procesos cooperantes, TLS establecido, puntos seguros y versiones compatibles. Acceso restringido al canal y a los secretos transferidos.],
      [Variable], [Tiempos], [Espera hasta el punto seguro, transferencia, pausa visible en cada extremo y retiro del proceso anterior.],
      [Variable], [Recursos y carga], [Uso de procesador (CPU) y memoria adicional; concurrencia, duración de conexiones y volumen de datos pendientes.],
      [Variable], [Integración], [Cambios en el #emph[proxy], tamaño de las adaptaciones y actividades necesarias para integrarlas.],
    ),
    note: [Se acepta una transferencia si cumple continuidad e integridad en los escenarios de prueba y el proceso anterior se retira. Las variables de costo se comparan bajo las mismas cargas; no se fijan umbrales numéricos antes de obtener mediciones.],
    target: label("requisitos"),
  )

  La evaluación compara el mismo #emph[proxy] con migración, con drenaje y sin actualización: el drenaje contrasta el tiempo de retiro y la ejecución sin actualización mide el costo añadido. Las pruebas registran además los rechazos y las transferencias incompletas, para delimitar el mecanismo.

  #heading-level-2("1.3", "Justificación del problema")

  La necesidad de esta biblioteca surge cuando se quiere retirar una versión del #emph[proxy] mientras sus conexiones continúan activas. Mantener la recepción de tráfico nuevo no resuelve ese objetivo: si las comunicaciones establecidas siguen en el proceso anterior, su retiro todavía depende de que terminen. Para transferir su atención, el proceso nuevo debe recuperar las dos conexiones, sus contextos TLS, el avance de los mensajes HTTP y la asociación entre solicitudes y respuestas.

  La @comparacion distingue lo que proporciona cada alternativa del trabajo que todavía exige este escenario. Ecdysis conserva la escucha y deja las conexiones aceptadas en el proceso anterior; Hot Restart Proxy traslada pares TCP, pero no incorpora la restauración TLS y HTTP. CRIU conserva la ejecución capturada, mientras que actualizar el código exige definir cómo interpretará otra versión el estado de aplicación. MOSN es un antecedente más cercano: migra la conexión con el cliente, pero establece una nueva hacia el servidor, según su documentación @mosn-upgrade. Por ello, ese procedimiento no conserva las dos conexiones que exige el proyecto.

  PRISM, XO y Capybara demuestran que trasladar estado TLS y HTTP es viable. Sus interfaces y mecanismos pueden servir como base, pero su escenario es redistribuir conexiones entre servidores. En particular, la implementación evaluada de Capybara utiliza una pila de red en espacio de usuario y un conmutador programable @capybara. Su adopción para actualizar un #emph[proxy] sobre #emph[sockets] existentes de Linux requiere adaptar la integración y comprobar la restauración de ambos lados entre versiones compatibles.

  El aporte propuesto consiste en reunir ese trabajo de integración en una biblioteca: coordinar el traspaso local, conectar adaptadores que exporten y restauren el estado TLS/HTTP y confirmar que el proceso nuevo puede continuar antes de retirar el anterior. Una interfaz común permitiría incorporar el mecanismo a un #emph[proxy] sin volver a diseñar toda la coordinación, aunque cada biblioteca de protocolos requiera su adaptador. La evaluación determinará si esta integración conserva las comunicaciones admitidas, cómo cambia el tiempo de retiro del proceso anterior frente al drenaje y qué costos introduce.

  #heading-level-2("1.4", "Objetivos")

  #heading-level-3("1.4.1", "Objetivo general")

  Desarrollar y evaluar una biblioteca en Rust, integrada en un #emph[proxy] con implementaciones adaptadas de TLS 1.3 y HTTP/1.1, que transfiera sus conexiones activas con clientes y servidores entre procesos de una misma máquina Linux, para actualizar el #emph[proxy] sin interrumpir las comunicaciones admitidas por el mecanismo.

  #heading-level-3("1.4.2", "Objetivos específicos")

  + Identificar el estado de conexión, TLS 1.3 y HTTP/1.1 de ambos lados y los puntos seguros de transferencia, para determinar las adaptaciones y condiciones de continuidad.
  + Diseñar la arquitectura, la interfaz de integración y el formato de intercambio de estado de la biblioteca, para coordinar una transferencia consistente entre versiones compatibles.
  + Implementar la biblioteca, las adaptaciones TLS y HTTP y un #emph[proxy] de demostración, para comprobar la transferencia de ambas conexiones y su estado asociado.
  + Evaluar continuidad, integridad, tiempos, pausa, CPU, memoria y esfuerzo de integración, con drenaje y ejecución sin actualización como referencias, para determinar la efectividad y los límites operativos.

  #heading-level-2("1.5", "Marco teórico")

  #heading-level-3("1.5.1", "Proxies y actualización de procesos")

  Un #emph[proxy] que termina conexiones mantiene una comunicación con el cliente y otra con el servidor de destino. HAProxy documenta que ambas son conexiones independientes, con procesamiento propio en cada lado @haproxy-management. En un intermediario HTTP, las solicitudes y respuestas se analizan y reenvían conforme a las reglas de delimitación y persistencia de HTTP/1.1 @rfc9112. Esta estructura sitúa el estado de transporte y de aplicación en el recorrido de una misma operación.

  NGINX, HAProxy y Envoy permiten reemplazar procesos conservando la recepción de tráfico: el proceso anterior atiende las conexiones existentes hasta completarlas o alcanzar el plazo de cierre @nginx-control @haproxy-management @envoy-hot-restart. Envoy indica expresamente que no las transfiere a la nueva instancia. Estos procedimientos constituyen el drenaje usado como referencia de evaluación. Multibinder @github-multibinder, ecdysis @cloudflare-ecdysis y listenfd @listenfd facilitan la herencia de recursos de escucha, sin trasladar el estado de las conexiones ya aceptadas.

  #heading-level-3("1.5.2", "Estado de transporte y protocolos de aplicación")

  TCP proporciona un flujo de bytes fiable y ordenado mediante números de secuencia, confirmaciones, ventanas y retransmisiones @rfc9293. En Linux, ese estado pertenece a un #emph[socket] del #emph[kernel]; el descriptor es la referencia mediante la cual un proceso accede al recurso. Los #emph[sockets] de dominio Unix permiten pasar descriptores con `SCM_RIGHTS`, mecanismo que entrega al receptor una referencia al mismo recurso abierto @linux-unix. Por tanto, un traspaso local puede conservar el #emph[socket] existente sin reconstruir la conexión TCP; los datos que la aplicación ya extrajo del #emph[kernel] requieren tratamiento separado.

  TLS 1.3 protege los registros con secretos de tráfico y números de secuencia independientes para envío y recepción. Su estado incluye la fase del protocolo, las claves vigentes y los registros pendientes; una actualización de claves modifica parte de ese contexto. La reanudación TLS establece una nueva comunicación a partir de información previa, por lo que no sustituye la conservación del contexto de una conexión activa @rfc8446. En un #emph[proxy] con TLS en ambos lados existen dos contextos independientes, correspondientes a sus papeles de servidor y cliente.

  HTTP/1.1 delimita mensajes mediante cabeceras y reglas como la longitud del contenido o la codificación por fragmentos. Una conexión persistente puede transportar varios intercambios; conservarla requiere conocer el avance del mensaje y los bytes pendientes de análisis o envío @rfc9112. El estado del #emph[proxy] también comprende la relación entre una solicitud recibida y la respuesta del destino. Así, el descriptor y las claves no describen por sí solos el avance del procesamiento.

  Las interfaces de bibliotecas concretas exponen partes diferentes de ese estado. La biblioteca TLS rustls documenta la extracción de secretos y contadores para configurar kTLS, mecanismo de Linux que procesa la capa de registros TLS @rustls-secrets @kernel-tls. La biblioteca HTTP Hyper permite recuperar el recurso de entrada y salida con `into_parts`, pero exige que el procesamiento haya terminado para no dejar bytes HTTP sin enviar @hyper-http1. La documentación establece condiciones específicas para estas operaciones parciales, sin describir en esas interfaces una restauración completa entre procesos.

  #heading-level-3("1.5.3", "Migración de conexiones y actualización de estado")

  Snoeren, Andersen y Balakrishnan estudiaron en 2001 la recuperación mediante migración de conexiones, combinando soporte de transporte con sincronización de estado de aplicación @tcp-failover. SockMi abordó posteriormente conexiones cifradas mediante un módulo de Linux, un servicio de migración y una biblioteca que exportaba estructuras de OpenSSL @sockmi-ssl. Sus pruebas empleaban versiones anteriores a TLS 1.3 y restauraban la ejecución con el mismo #emph[software].

  CRIU (#emph[Checkpoint/Restore In Userspace]) es una herramienta que captura y restaura procesos Linux, incluidos sus recursos y memoria; también ofrece libsoccr como biblioteca para conservar conexiones TCP @criu. `TCP_REPAIR` es el modo de Linux que permite detener el procesamiento normal de una conexión y consultar o restaurar su estado, utilizado por esa biblioteca @libsoccr. COAT combina CRIU, contenedores y una red virtual para trasladar ejecuciones en el borde de la red @coat. Estos mecanismos restauran el estado capturado, sin definir automáticamente su conversión para otra versión del programa.

  La actualización dinámica estudia esa conversión. Kitsune permite actualizar programas en C mediante puntos indicados por el desarrollador y transformaciones de datos @kitsune. MOSN documenta una actualización local que pasa la conexión del cliente, sus búferes y el estado TLS mediante un canal Unix; la nueva instancia establece otra conexión con el servidor de destino @mosn-upgrade. Como antecedente en Rust, el proyecto de demostración Hot Restart Proxy pasa pares de conexiones TCP entre procesos, aunque la demostración no incorpora estado TLS ni análisis HTTP @hot-restart-proxy. La @comparacion resume qué proporciona cada mecanismo y qué resta integrar o validar para conservar ambos lados durante una actualización local.

  #chapter-table(
    [Aporte de los mecanismos existentes y trabajo pendiente para el proyecto],
    ruled-table(
      columns: (1.15fr, 2.35fr, 3.5fr),
      table.header([*Alternativa*], [*Qué proporciona*], [*Qué falta para este proyecto*]),
      [Ecdysis @cloudflare-ecdysis], [Conserva los recursos de escucha durante el reemplazo local del proceso.], [Trasladar las conexiones aceptadas: permanecen en el proceso anterior y su retiro espera a que terminen.],
      [Hot Restart Proxy @hot-restart-proxy], [Transfiere pares de conexiones TCP entre procesos Linux.], [Restaurar los dos contextos TLS y el estado HTTP; la demostración no incorpora esos protocolos.],
      [CRIU / libsoccr @criu @libsoccr], [CRIU restaura el proceso y su memoria; libsoccr conserva el recurso TCP.], [Definir la restauración del estado en otra versión del programa. libsoccr no trata TLS ni HTTP.],
      [SockMi @sockmi-ssl], [Exporta conexiones cifradas con OpenSSL mediante una biblioteca y un módulo Linux.], [Adaptar el mecanismo a TLS 1.3 y validar HTTP. Sus pruebas usan TLS anterior y el mismo programa.],
      [MOSN @mosn-upgrade], [Migra localmente la conexión con el cliente, sus búferes y el estado TLS.], [Conservar también la conexión con el servidor: MOSN establece otra. Extraer su mecanismo del #emph[proxy] Go para integrarlo como biblioteca.],
      [PRISM @prism], [Transfiere conexiones y estado TLS/HTTP a servidores, con una red programable.], [Adaptar su API al reemplazo local de versiones y al traspaso conjunto de ambos lados del #emph[proxy].],
      [XO @xo], [Traslada conexiones y estado TLS/HTTP entre un balanceador y servidores, mediante eBPF.], [Integrar la descarga de conexiones en una actualización local que preserve ambos lados y su asociación.],
      [Capybara @capybara], [Exporta e importa TCP, TLS con TLSe y solicitudes HTTP parciales; su prototipo usa Demikernel.], [Adaptar la implementación a #emph[sockets] de Linux y validar ambos lados del #emph[proxy] entre versiones compatibles.],
    ),
    note: [La columna final identifica integración o validación pendiente para el escenario propuesto; no afirma que extender estos sistemas sea imposible.],
    target: label("comparacion"),
  )

  #heading-level-3("1.5.4", "Transferencia en funciones de red y balanceo de carga")

  OpenNF @opennf y HA/TCP @ha-tcp estudian el cambio del responsable de una comunicación mediante transferencia coordinada o réplicas sincronizadas; HA/TCP requiere además una pila FreeBSD modificada en espacio de usuario. Los sistemas de redistribución entre servidores de la @comparacion difieren en su infraestructura: PRISM utiliza un conmutador programable; XO, eBPF, infraestructura de Linux que ejecuta programas verificados para funciones como la redirección de paquetes; y Capybara, Demikernel, una pila de red que procesa paquetes fuera del #emph[kernel], y almacenamiento temporal del tráfico.

  Las mediciones de la @mediciones corresponden a unidades y entornos distintos y no permiten comparar velocidades entre sistemas. La migración de conexión de QUIC tiene otro significado: permite cambiar direcciones o rutas de una comunicación y no especifica cómo transferir la memoria de un #emph[proxy] entre versiones @rfc9000.

  #chapter-table(
    [Mediciones seleccionadas y su contexto experimental],
    ruled-table(
      columns: (1.05fr, 2.65fr, 2.6fr),
      table.header([*Sistema*], [*Operación y entorno*], [*Medición publicada*]),
      [PRISM @prism], [Ciclo entre servidores Linux: destino, entrada y otro destino; red programable.], [232 µs por ciclo; 109 µs corresponden a restaurar TLS.],
      [HA/TCP @ha-tcp], [Cambio entre réplicas sincronizadas; pila TCP en espacio de usuario, red de 100 Gb/s.], [38 µs para el traspaso; no incluye la detección del fallo.],
      [Capybara @capybara], [Mantenimiento de Redis, un almacén de datos en memoria, con TLS: 16 conexiones entre un servidor principal y uno de respaldo; infraestructura Demikernel.], [Unos 200 ms para recuperar el rendimiento tras el cierre; la migración previa conserva el rendimiento en esa prueba.],
    ),
    note: [Valores reportados por los autores en sus entornos.],
    target: label("mediciones"),
  )
]
