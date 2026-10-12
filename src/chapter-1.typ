#import "style.typ": heading-level-1, heading-level-2, heading-level-3
#import "chapter-visuals.typ": chapter-figure, chapter-table, ruled-table

#let chapter-one() = [
  #heading-level-1("CAPÍTULO 1")

  #heading-level-2("1.1", "Introducción")

  Los servicios digitales necesitan corregir vulnerabilidades, incorporar funciones y modificar configuraciones mientras atienden a sus usuarios. Estas tareas suelen exigir el reemplazo de procesos que mantienen comunicaciones activas. En esa infraestructura, los #emph[proxies] balanceadores de carga son programas intermediarios que reciben solicitudes de clientes y las distribuyen entre servidores. Su actualización afecta tanto la recepción de tráfico nuevo como la continuidad de las comunicaciones que ya atienden.

  La duración de esas comunicaciones condiciona el mantenimiento. Cloudflare documentó que Oxy, su plataforma para construir #emph[proxies] en Rust, atiende conexiones prolongadas destinadas a respaldos, actualizaciones en tiempo real y sesiones remotas. El artículo explica que esperar un periodo de menor actividad no resuelve el problema cuando una corrección de seguridad requiere desplegarse de inmediato @cloudflare-oxy.

  Una práctica habitual consiste en iniciar la nueva versión y mantener la anterior hasta que complete sus comunicaciones, procedimiento denominado drenaje. Así se conserva el servicio, pero el retiro del código anterior depende del trabajo pendiente. La migración modifica esa dependencia al trasladar la atención de las conexiones a la nueva versión. La @actualizacion representa ambos procedimientos y distingue el inicio de la actualización del retiro efectivo del proceso anterior.

  #chapter-figure(
    [Drenaje y migración durante una actualización],
    image("figures/actualizacion.svg", width: 100%),
    note: [Esquema conceptual sin escala temporal. La migración incluye la espera hasta una condición de captura consistente y el traspaso; no implica una pausa nula.],
    target: label("actualizacion"),
  )

  El proyecto integrador se orienta a una biblioteca reutilizable en Rust que transfiera conexiones activas y su estado entre procesos de una misma máquina Linux. Comprende comunicaciones protegidas con TLS 1.3, protocolo de seguridad para cifrar el intercambio, y HTTP/1.1, protocolo que organiza solicitudes y respuestas. La propuesta integra el componente en el código de un #emph[proxy] y requiere cooperación de las implementaciones de esos protocolos.

  Su desarrollo aplica contenidos de Sistemas Operativos, Seguridad de la Información y Sistemas Distribuidos y Computación en la Nube: administración de recursos, coordinación entre procesos, protección del estado criptográfico y evaluación bajo concurrencia. Para los desarrolladores de #emph[proxies], aporta una interfaz de integración y adaptaciones documentadas; para los equipos de operación, evidencia sobre continuidad y tiempo de mantenimiento. Su utilidad potencial consiste en actualizar infraestructura compartida sin exigir reconexiones a los usuarios de las comunicaciones transferidas.

  El capítulo 2 presentará las alternativas, el diseño y la metodología de implementación y evaluación. El capítulo 3 analizará continuidad, costos y esfuerzo de integración. El capítulo 4 expondrá las conclusiones por objetivo y las recomendaciones.

  #heading-level-2("1.2", "Descripción del problema")

  El problema abordado es la falta, en las soluciones examinadas, de un componente reutilizable en Rust que reúna la transferencia local de conexiones aceptadas de un #emph[proxy], la conservación de su estado TLS 1.3 y HTTP/1.1 en ambos lados y una interfaz independiente de un #emph[proxy] particular. Existen mecanismos de migración, pero su adopción depende de plataformas, pilas de red o adaptaciones específicas. Por ello, el problema comprende definir qué estado debe exponer la aplicación, cómo coordinar el traspaso y bajo qué condiciones puede continuar la comunicación.

  El escenario principal es una actualización planificada entre dos procesos cooperantes en la misma máquina Linux. El #emph[proxy] mantiene dos conexiones independientes del protocolo de control de transmisión (TCP): cliente–#emph[proxy] y #emph[proxy]–servidor de destino. En ambas utiliza TLS 1.3 y HTTP/1.1, actuando como servidor frente al cliente y como cliente frente al destino. La transferencia comprende las dos conexiones, sus datos pendientes y la asociación que permite encaminar cada solicitud y respuesta, como representa la @estado-conexiones.

  #chapter-figure(
    [Conexiones y estado que conserva el proxy],
    image("figures/estado-conexiones.svg", width: 88%),
    note: [Los contextos TLS son independientes. Linux conserva los recursos TCP; el proceso, el estado de protocolos y la asociación entre conexiones.],
    target: label("estado-conexiones"),
  )

  Un punto de integración es el lugar del código donde el #emph[proxy] invoca la biblioteca para registrar, transferir o restaurar una conexión. Un punto seguro es una condición de ejecución en la que puede capturarse un estado consistente, sin lecturas, escrituras o tareas concurrentes que lo modifiquen. Los adaptadores son componentes que conectan la interfaz de la biblioteca con una implementación concreta de TLS o HTTP. El diseño determina los puntos seguros admitidos y si incluyen mensajes HTTP en curso; la garantía de continuidad se restringe a esos estados, sin prometer una transferencia válida en cualquier instante.

  La entrega principal comprende la biblioteca, las adaptaciones de TLS 1.3 y HTTP/1.1 para ambos lados y un #emph[proxy] sencillo de demostración. Solo se admite compatibilidad con las bibliotecas adaptadas y con las versiones cuyo formato de estado se comprueba. La selección de dependencias está condicionada a una prueba de exportación y restauración; no se presupone que sus interfaces actuales resuelven ambas operaciones. La validación utiliza un solo #emph[proxy], por lo que la reutilización se argumenta mediante el diseño y la documentación, sin demostrar aplicabilidad a cualquier intermediario.

  HTTP/2 constituye una extensión opcional. Quedan fuera el traslado entre máquinas, la recuperación ante fallos abruptos, las aplicaciones sin cooperación y QUIC/HTTP/3. Los usuarios previstos son desarrolladores y operadores de infraestructura digital; el proyecto no tiene una organización cliente identificada. La @requisitos reúne las condiciones y variables que hacen observable el problema.

  #chapter-table(
    [Requisitos, restricciones y variables de evaluación],
    ruled-table(
      columns: (1.1fr, 1.45fr, 3.45fr),
      table.header([*Tipo*], [*Elemento*], [*Condición o medición*]),
      [Requisito], [Continuidad], [Ambas conexiones continúan sin reconexión ni un nuevo establecimiento de TLS causado por el traspaso.],
      [Requisito], [Integridad], [Contenido y orden conservados en ambas direcciones, sin pérdida, duplicación ni alteración de los datos entregados.],
      [Requisito], [Responsabilidad], [Se conserva la asociación entre conexiones; el destino confirma la restauración antes del retiro del origen.],
      [Restricción], [Entorno y estado], [Linux local, procesos cooperantes, TLS establecido, puntos seguros y versiones compatibles. Acceso restringido al canal y a los secretos transferidos.],
      [Variable], [Tiempos], [Espera hasta el punto seguro, transferencia, pausa visible en cada extremo y retiro del proceso anterior.],
      [Variable], [Recursos y carga], [Uso de procesador (CPU) y memoria adicional; concurrencia, duración de conexiones y volumen de datos pendientes.],
      [Variable], [Integración], [Cambios en el #emph[proxy], tamaño de las adaptaciones y actividades necesarias para integrarlas.],
    ),
    note: [Criterios del proyecto. Las variables de costo se comparan bajo las mismas cargas; no se fijan umbrales numéricos antes de obtener mediciones.],
    target: label("requisitos"),
  )

  La aceptación exige continuidad e integridad en todas las transferencias admitidas por los escenarios de prueba, además del retiro del proceso anterior. La evaluación compara el mismo #emph[proxy] con migración, con drenaje y sin actualización. El drenaje permite contrastar el tiempo de retiro y la ejecución sin actualización permite medir el costo añadido; no se presupone una mejora simultánea en todas las métricas. Las pruebas también registran rechazos y transferencias incompletas para determinar los límites del mecanismo.

  #heading-level-2("1.3", "Justificación del problema")

  La revisión de artículos, documentación de NGINX, HAProxy y Envoy, y componentes públicos del ecosistema Rust no identifica una biblioteca que reúna todos los requisitos de este proyecto. Esta afirmación se limita a las fuentes examinadas y no supone que la migración carezca de soluciones. Ecdysis facilita reinicios en Rust mediante herencia de recursos de escucha y drenaje; MOSN transfiere estado dentro de su plataforma; Capybara ofrece interfaces de exportación e importación sobre una pila de red distinta de la de Linux @cloudflare-ecdysis @mosn-upgrade @capybara.

  La contribución comprende tres resultados: una biblioteca para coordinar el traspaso local, adaptaciones que expongan y restauren estado TLS y HTTP, y una evaluación de continuidad, costos y esfuerzo de integración. Se elige una biblioteca porque permite separar el mecanismo de transferencia de las políticas de balanceo del #emph[proxy]. Rust ofrece un modelo de propiedad de recursos comprobado por el compilador @rust-ownership. Su uso requiere igualmente verificar la consistencia del estado y revisar las operaciones que interactúan con el sistema operativo.

  Esta delimitación evita desarrollar un #emph[proxy] de producción o un módulo del #emph[kernel] para estudiar la actualización. Los resultados pueden ayudar a valorar cuándo una transferencia reduce la permanencia de versiones anteriores y qué adaptaciones exige. El beneficio para los usuarios se concreta en evitar reconexiones y conservar los datos de las comunicaciones evaluadas, sin extrapolar esas pruebas a la disponibilidad de servicios completos.

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

  La documentación de NGINX describe una actualización del ejecutable en la que los procesos anteriores atienden a sus clientes hasta completar el trabajo @nginx-control. HAProxy aplica un cierre gradual: deja de escuchar y continúa con las conexiones existentes hasta que se cierran @haproxy-management. Envoy hereda recursos de escucha, drena las conexiones anteriores y cierra las que permanecen al terminar el proceso; su documentación indica expresamente que no las transfiere a la nueva instancia @envoy-hot-restart. Estos procedimientos son antecedentes del drenaje usado como referencia de evaluación.

  GitHub desarrolló multibinder para compartir recursos de escucha entre instancias de HAProxy y conservar conexiones pendientes de aceptación @github-multibinder. Ecdysis proporciona esta clase de reinicio como biblioteca en Rust, mientras la aplicación completa sus conexiones aceptadas mediante drenaje @cloudflare-ecdysis. Listenfd facilita recibir descriptores administrados externamente y activar recursos de escucha @listenfd. La documentación de esos componentes trata la recepción de tráfico y la vida de los procesos, sin aportar por sí sola adaptadores de restauración TLS y HTTP.

  #heading-level-3("1.5.2", "Estado de transporte y protocolos de aplicación")

  TCP proporciona un flujo de bytes fiable y ordenado mediante números de secuencia, confirmaciones, ventanas y retransmisiones @rfc9293. En Linux, ese estado pertenece a un #emph[socket] del #emph[kernel]; el descriptor es la referencia mediante la cual un proceso accede al recurso. Los #emph[sockets] de dominio Unix permiten pasar descriptores con `SCM_RIGHTS`, mecanismo que entrega al receptor una referencia al mismo recurso abierto @linux-unix. Por tanto, un traspaso local puede conservar el #emph[socket] existente sin reconstruir la conexión TCP; los datos que la aplicación ya extrajo del #emph[kernel] requieren tratamiento separado.

  TLS 1.3 protege los registros con secretos de tráfico y números de secuencia independientes para envío y recepción. Su estado incluye la fase del protocolo, las claves vigentes y los registros pendientes; una actualización de claves modifica parte de ese contexto. La reanudación TLS establece una nueva comunicación a partir de información previa, por lo que no sustituye la conservación del contexto de una conexión activa @rfc8446. En un #emph[proxy] con TLS en ambos lados existen dos contextos independientes, correspondientes a sus papeles de servidor y cliente.

  HTTP/1.1 delimita mensajes mediante cabeceras y reglas como la longitud del contenido o la codificación por fragmentos. Una conexión persistente puede transportar varios intercambios; conservarla requiere conocer el avance del mensaje y los bytes pendientes de análisis o envío @rfc9112. El estado del #emph[proxy] también comprende la relación entre una solicitud recibida y la respuesta del destino. Así, el descriptor y las claves no describen por sí solos el avance del procesamiento.

  Las interfaces de bibliotecas concretas exponen partes diferentes de ese estado. La biblioteca TLS rustls documenta la extracción de secretos y contadores para configurar kTLS, mecanismo de Linux que procesa la capa de registros TLS @rustls-secrets @kernel-tls. La biblioteca HTTP Hyper permite recuperar el recurso de entrada y salida con `into_parts`, pero exige que el procesamiento haya terminado para no dejar bytes HTTP sin enviar @hyper-http1. La documentación establece condiciones específicas para estas operaciones parciales, sin describir en esas interfaces una restauración completa entre procesos.

  #heading-level-3("1.5.3", "Migración de conexiones y actualización de estado")

  Snoeren, Andersen y Balakrishnan estudiaron en 2001 la recuperación mediante migración de conexiones, combinando soporte de transporte con sincronización de estado de aplicación @tcp-failover. SockMi abordó posteriormente conexiones cifradas mediante un módulo de Linux, un servicio de migración y una biblioteca que exportaba estructuras de OpenSSL @sockmi-ssl. Sus pruebas empleaban versiones anteriores a TLS 1.3 y restauraban la ejecución con el mismo #emph[software].

  CRIU (#emph[Checkpoint/Restore In Userspace]) es una herramienta que captura y restaura procesos Linux, incluidos sus recursos y memoria; también ofrece libsoccr como biblioteca para conservar conexiones TCP @criu. `TCP_REPAIR` es el modo de Linux que permite detener el procesamiento normal de una conexión y consultar o restaurar su estado, utilizado por esa biblioteca @libsoccr. COAT combina CRIU, contenedores y una red virtual para trasladar ejecuciones en el borde de la red @coat. Estos mecanismos restauran el estado capturado, sin definir automáticamente su conversión para otra versión del programa.

  La actualización dinámica estudia esa conversión. Kitsune permite actualizar programas en C mediante puntos indicados por el desarrollador y transformaciones de datos @kitsune. MOSN documenta una actualización local entre procesos que pasa descriptores, búferes de lectura y estado TLS mediante un canal Unix; coordina además escrituras y respuestas todavía atendidas por la instancia anterior @mosn-upgrade. Como antecedente en Rust, el proyecto de demostración Hot Restart Proxy pasa pares de conexiones TCP entre procesos, aunque el código revisado no incorpora estado TLS ni análisis HTTP @hot-restart-proxy. La @comparacion distingue las unidades de transferencia y las formas de reutilización documentadas.

  #chapter-table(
    [Mecanismos de continuidad y formas de reutilización],
    ruled-table(
      columns: (1.25fr, 1.8fr, 2.1fr, 2fr),
      table.header([*Sistema*], [*Unidad y entorno*], [*Estado TLS y HTTP*], [*Reutilización documentada*]),
      [Ecdysis @cloudflare-ecdysis], [Recursos de escucha; reinicio local.], [Conexiones aceptadas completadas en el origen.], [Biblioteca Rust; no restaura estos protocolos.],
      [MOSN @mosn-upgrade], [Conexión aceptada; canal Unix local.], [TLS y búferes; procesamiento dependiente del protocolo.], [Mecanismo integrado en el #emph[proxy] Go.],
      [SockMi @sockmi-ssl], [Conexión; módulo Linux y servicio.], [Estado OpenSSL anterior a TLS 1.3; HTTP no evaluado.], [Biblioteca de aplicación y módulo específicos.],
      [CRIU / libsoccr @criu @libsoccr], [Proceso completo o recurso TCP; Linux.], [El proceso incluye su memoria; libsoccr solo trata TCP.], [Herramienta y bibliotecas; sin adaptación automática de versiones.],
      [Hot Restart Proxy @hot-restart-proxy], [Par de conexiones TCP; canal Unix local.], [El código examinado no incorpora TLS ni estado HTTP.], [Demostración Rust, ligada a su aplicación.],
      [PRISM @prism], [Conexión entre servidores; Linux y red programable.], [TLS y estado HTTP serializados para atender solicitudes.], [API del sistema de transferencia.],
      [XO @xo], [Conexión entre servidores; Linux y redirección programable.], [Contexto TLS y estado de la solicitud.], [Sistema de descarga con integración en aplicaciones.],
      [Capybara @capybara], [Conexión entre servidores; Demikernel y conmutador programable.], [TLS con TLSe y solicitudes HTTP parciales.], [Interfaces de exportación e importación; componente Rust sobre su pila de red.],
    ),
    note: [Comparación de las fuentes citadas. Tener una API o una biblioteca no equivale a cubrir el escenario local completo del proyecto. La ausencia de evaluación HTTP en una fuente no demuestra que el sistema sea incapaz de soportarlo.],
    target: label("comparacion"),
  )

  #heading-level-3("1.5.4", "Transferencia en funciones de red y balanceo de carga")

  OpenNF coordina interfaces de exportación e importación de estado con cambios en el encaminamiento para evitar pérdida y desorden durante el traslado de flujos @opennf. HA/TCP utiliza réplicas previamente sincronizadas y una pila FreeBSD modificada en espacio de usuario para asumir conexiones de funciones de red @ha-tcp. Ambos trabajos tratan la consistencia durante el cambio del responsable de una comunicación, mediante transferencia controlada o replicación.

  PRISM transfiere conexiones y estado TLS y HTTP para que servidores de destino respondan directamente a clientes @prism. XO aplica una descarga similar con red convencional y eBPF, infraestructura de Linux que ejecuta programas verificados para funciones como la redirección de paquetes @xo. Capybara utiliza exportación e importación del estado de aplicación, una pila Demikernel implementada en Rust y almacenamiento temporal de tráfico durante el cambio de servidor. Sus ejemplos incluyen solicitudes HTTP incompletas y contextos TLS serializados con TLSe @capybara.

  Las mediciones de la @mediciones corresponden a unidades y entornos distintos, no a una comparación directa de velocidad entre sistemas. En particular, la prueba de mantenimiento de Capybara documenta el costo de reconectarse tras un cierre y el efecto de migrar previamente. La migración de conexión de QUIC tiene otro significado: permite cambiar direcciones o rutas de una comunicación y no especifica cómo transferir la memoria de un #emph[proxy] entre versiones @rfc9000.

  #chapter-table(
    [Mediciones seleccionadas y su contexto experimental],
    ruled-table(
      columns: (1.05fr, 2.65fr, 2.6fr),
      table.header([*Sistema*], [*Operación y entorno*], [*Medición publicada*]),
      [PRISM @prism], [Ciclo entre servidores Linux: destino, entrada y otro destino; red programable.], [232 µs por ciclo; 109 µs corresponden a restaurar TLS.],
      [HA/TCP @ha-tcp], [Cambio entre réplicas sincronizadas; pila TCP en espacio de usuario, red de 100 Gb/s.], [38 µs para el traspaso; no incluye la detección del fallo.],
      [Capybara @capybara], [Mantenimiento de Redis con TLS: 16 conexiones entre un servidor principal y uno de respaldo; infraestructura Demikernel.], [Unos 200 ms para recuperar el rendimiento tras el cierre; la migración previa conserva el rendimiento en esa prueba.],
    ),
    note: [Valores reportados por los autores; no son umbrales del prototipo ni mediciones de actualización local entre versiones.],
    target: label("mediciones"),
  )
]
