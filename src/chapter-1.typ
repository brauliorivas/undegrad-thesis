#import "style.typ": heading-level-1, heading-level-2, heading-level-3

#let chapter-one() = [
  #heading-level-1("CAPÍTULO 1")

  #heading-level-2("1.1", "Introducción")

  Los servicios en línea requieren actualizar su infraestructura mientras atienden comunicaciones activas. En ese entorno, los proxies balanceadores de carga reciben conexiones de clientes, seleccionan servidores de destino y, según su función, terminan conexiones cifradas o interpretan solicitudes HTTP. Su actualización plantea una dificultad particular: el proceso que ejecuta la versión anterior conserva información necesaria para continuar las comunicaciones que ya inició. Por tanto, disponer de una nueva instancia capaz de aceptar tráfico no garantiza que las conexiones existentes sobrevivan al retiro de la anterior.

  La experiencia publicada por operadores de infraestructura evidencia la relevancia del problema. GitHub presentó mecanismos para renovar sus proxies HAProxy preservando los sockets de escucha y evitando pérdidas de conexiones pendientes de aceptación @github-multibinder. Cloudflare describió las dificultades de actualizar Oxy cuando existen comunicaciones prolongadas, como respaldos y sesiones remotas, y la tensión entre esperar su finalización y desplegar correcciones urgentes @cloudflare-oxy. En un intercambio técnico de Fly.io de 2021, un integrante del equipo explicó que el proxy esperaba hasta cuatro minutos durante su apagado; un usuario señaló que ese intervalo no evitaba interrumpir transmisiones más largas @fly-long-connections. Este último caso constituye un antecedente documentado, no una afirmación sobre los límites actuales del servicio.

  Estas experiencias motivan el estudio de la continuidad de conexiones durante actualizaciones planificadas. La estrategia de drenaje permite que el proceso anterior complete sus comunicaciones mientras el nuevo recibe otras. Sin embargo, su duración depende de las conexiones pendientes. Transferirlas a la nueva instancia ofrece una alternativa que exige conservar tanto el recurso de transporte como el estado que mantienen los protocolos superiores.

  El proyecto se desarrolla en el ámbito de Computación y articula conocimientos de redes, sistemas operativos, programación concurrente, seguridad e ingeniería de software. Su pertinencia formativa reside en convertir un problema operativo en requisitos verificables, diseñar una biblioteca y evaluar su comportamiento mediante experimentos reproducibles. La vinculación con el sector de comunicaciones e información se concreta en un prototipo que puede servir de base para herramientas de mantenimiento de infraestructura. Sus beneficiarios potenciales son desarrolladores y operadores de plataformas que sostienen servicios digitales, así como los usuarios que dependen de su continuidad.

  El trabajo se orienta a una biblioteca en Rust integrada en un proxy de demostración, con transferencia entre procesos de una misma máquina Linux y conservación del estado necesario de TLS 1.3 y HTTP/1.1. El informe presentará primero el problema, su justificación, los objetivos y los fundamentos teóricos. Posteriormente desarrollará el diseño y la metodología de implementación y evaluación; expondrá los resultados experimentales y su análisis; y finalizará con las conclusiones y recomendaciones.

  #heading-level-2("1.2", "Descripción del problema")

  El problema consiste en reemplazar el proceso de un proxy sin obligar a los clientes a restablecer las conexiones que mantiene activas. Se considera una actualización planificada en la que las instancias de origen y destino pueden cooperar. El destinatario técnico es el sector de proveedores de infraestructura y plataformas en línea; los casos empresariales citados son antecedentes públicos y no implican una relación de contratación o patrocinio del proyecto.

  Un proxy que termina TCP mantiene una conexión con el cliente y otra con el servidor de destino. Además de esos sockets, puede conservar bytes pendientes de envío, datos ya leídos y asociaciones entre solicitudes y respuestas. Si termina TLS, también mantiene información criptográfica y de procesamiento de registros; si interpreta HTTP, conserva el avance del procesamiento de mensajes. La migración debe respetar esas relaciones para que la nueva instancia continúe desde un estado consistente. Los trabajos de PRISM y Capybara muestran que el estado de las capas superiores forma parte del problema de transferencia de conexiones @prism @capybara.

  El requisito central es preservar la comunicación sin pérdida, duplicación ni alteración de los datos entregados a la aplicación. La instancia de origen debe dejar de operar sobre los recursos transferidos antes de que el destino asuma su uso. Asimismo, el diseño debe delimitar cuándo se considera completada la transferencia y cómo se responde a un rechazo del destino. No basta con comprobar que el descriptor llega al nuevo proceso: la prueba debe verificar que la comunicación continúa y que el proceso anterior puede retirarse.

  El prototipo contempla sockets TCP del núcleo de Linux, TLS 1.3 y HTTP/1.1, con migración en puntos seguros definidos por los adaptadores. Un punto seguro es una condición del procesamiento en la que el estado exportado resulta consistente y no existen operaciones concurrentes que lo modifiquen. Esperar ese punto puede introducir demora; por ello, la evaluación distingue la espera previa de la transferencia efectiva. El diseño debe documentar los estados admitidos y rechazar explícitamente los que no soporta, en lugar de intentar una restauración incompleta.

  El canal local de transferencia debe restringirse a procesos autorizados y evitar que el estado criptográfico se exponga en registros o archivos temporales. La biblioteca requiere cooperación del proxy y acceso al estado de sus implementaciones de protocolos. Su alcance no comprende migrar aplicaciones arbitrarias sin modificaciones, mover conexiones entre máquinas, recuperar un proceso que falla abruptamente ni garantizar compatibilidad entre cualquier par de versiones. El intercambio se limita a versiones del prototipo que compartan un formato de estado compatible. HTTP/2 queda como extensión condicionada al tiempo disponible; QUIC y HTTP/3 quedan fuera del alcance principal.

  Las variables de interés son la proporción de conexiones que continúan sin reconexión, los errores de integridad del flujo, la duración de la migración, la pausa observable por el cliente, el tiempo hasta retirar el proceso anterior y la sobrecarga de CPU y memoria. Se consideran como factores experimentales la concurrencia, el volumen de datos pendientes y la actividad de las conexiones. La comparación contempla ejecución sin actualización, drenaje y migración bajo cargas equivalentes. Estos indicadores permiten determinar si el mecanismo aporta continuidad y con qué costo, sin presuponer mejoras antes de medirlas.

  #heading-level-2("1.3", "Justificación del problema")

  Resolver este problema permite estudiar una forma de desacoplar el retiro de una versión del proxy de la duración de sus conexiones. En servicios con comunicaciones persistentes, una actualización que depende exclusivamente del drenaje puede prolongar la coexistencia de procesos; imponer un plazo implica aceptar la posibilidad de interrupciones. La propuesta busca reducir esa dependencia mediante una transferencia explícita y verificable del estado.

  La utilidad tecnológica reside en reunir la coordinación de procesos, el traspaso de sockets y la conservación de protocolos en una biblioteca integrable. El resultado esperado no es sustituir proxies comerciales ni demostrar una solución universal, sino producir un componente experimental con interfaces, restricciones y pruebas documentadas. Esto permite evaluar su adopción y reconocer qué cambios exige a las bibliotecas de protocolos.

  La justificación académica se apoya en la existencia de soluciones con propósitos y supuestos diferentes. PRISM estudia la transferencia entre frontends y backends para reducir el costo del proxy; Capybara utiliza migración para redistribuir carga; MOSN documenta actualizaciones con transferencia de conexiones dentro de su plataforma @prism @capybara @mosn-upgrade. Frente a esos antecedentes, este proyecto delimita su aporte a la implementación y evaluación de una biblioteca en Rust para actualizaciones locales, con soporte explícito de TLS 1.3 y HTTP/1.1. No plantea la migración de conexiones como una técnica inédita.

  En el plano productivo, el prototipo puede aportar evidencia para reducir reconexiones y trabajo repetido durante mantenimientos. No se atribuyen ahorros económicos cuantificados sin datos de operación. Su contribución social es indirecta: favorecer la continuidad de servicios que utilizan personas y organizaciones y ofrecer una base para transferencia tecnológica. Esta orientación es coherente con el interés del proyecto por infraestructura resiliente; no se prevé demostrar un impacto ambiental directo.

  #heading-level-2("1.4", "Objetivos")

  #heading-level-3("1.4.1", "Objetivo general")

  Desarrollar y evaluar una biblioteca en Rust para migrar conexiones TCP activas entre procesos de un proxy en la misma máquina, preservando el estado necesario de TLS 1.3 y HTTP/1.1 para mantener la continuidad de la comunicación.

  #heading-level-3("1.4.2", "Objetivos específicos")

  // Se conserva el alcance de la ficha; se explicita la finalidad de cada etapa.
  + Identificar el estado de TCP, TLS 1.3 y HTTP/1.1 que debe conservarse durante la migración y definir los puntos seguros de transferencia, para establecer las condiciones de continuidad de la comunicación.
  + Diseñar la arquitectura de la biblioteca y el formato de intercambio de estado entre las instancias de origen y destino del proxy, para coordinar una transferencia consistente y compatible.
  + Implementar la transferencia del socket TCP y los adaptadores necesarios para migrar el estado de TLS 1.3 y HTTP/1.1 en un proxy de demostración, para materializar y verificar el mecanismo propuesto.
  + Evaluar el prototipo mediante pruebas de continuidad de conexiones, tiempo de migración y sobrecarga durante una actualización del proxy, para determinar su efectividad y sus límites operativos.

  #heading-level-2("1.5", "Marco teórico")

  #heading-level-3("1.5.1", "Disponibilidad y actualización de infraestructura de red")

  La literatura distingue mecanismos que mantienen el acceso al servicio de aquellos que conservan comunicaciones particulares. En el contexto nacional, Rueda Hormaza y Andrade Mora desarrollaron en ESPOL un sistema de alta disponibilidad para acceso a Internet orientado a PYMEs. Su propuesta utilizó dos proveedores, balanceo de tráfico y pruebas de conmutación ante fallos @espol-disponibilidad. Este antecedente aborda continuidad mediante redundancia de conectividad; su alcance publicado no corresponde al traslado del estado TLS y HTTP entre versiones de un proxy.

  En la infraestructura de GitHub, GLB permite retirar servidores de la recepción de conexiones nuevas mientras las existentes permanecen asociadas a sus proxies hasta completar el drenaje @github-glb. Complementariamente, multibinder conserva sockets de escucha compartidos para evitar que una recarga descarte conexiones en la cola de aceptación @github-multibinder. Ambos mecanismos atienden etapas diferentes del ciclo de una conexión: admisión de tráfico y finalización de comunicaciones existentes.

  Cloudflare describió para Oxy un esquema en el cual la instancia nueva recibe conexiones mientras la anterior completa su trabajo @cloudflare-oxy. Su publicación de 2026 sobre ecdysis presenta otra biblioteca de reinicio gradual en Rust, cuyo ejemplo mantiene el drenaje de las conexiones del proceso anterior @cloudflare-ecdysis. Estos antecedentes muestran que un reinicio gradual puede preservar el servicio mediante coexistencia temporal de versiones, sin trasladar necesariamente las conexiones ya aceptadas al nuevo proceso.

  #heading-level-3("1.5.2", "Estado de TCP y transferencia local de sockets")

  TCP proporciona un flujo de bytes fiable y ordenado. La especificación mantiene información por conexión, incluidos números de secuencia, ventanas, datos pendientes y estados de establecimiento y cierre @rfc9293. Ese estado permite distinguir los bytes enviados, reconocidos y pendientes, y explica por qué abrir otro socket no reproduce por sí solo una conexión establecida.

  En Linux, los sockets de dominio Unix permiten transmitir referencias a descriptores mediante mensajes auxiliares de tipo `SCM_RIGHTS`. El receptor obtiene un descriptor referido al mismo recurso del núcleo, aunque su número local puede ser diferente @unix-rights. En una transferencia dentro de la misma máquina, esta propiedad permite conservar el socket TCP existente. No transfiere automáticamente los objetos, búferes o tareas que la aplicación mantiene en su memoria.

  La migración entre máquinas requiere mecanismos adicionales. CRIU documenta el uso de `TCP_REPAIR` para capturar y restaurar conexiones establecidas, junto con medidas de aislamiento de tráfico durante el procedimiento @criu-tcp. Su unidad de restauración pertenece al contexto de checkpoint y recuperación de procesos. Conservar una imagen de ejecución y entregar estado seleccionado a una versión nueva de un programa son operaciones con requisitos distintos.

  #heading-level-3("1.5.3", "Continuidad del estado TLS y HTTP")

  TLS 1.3 protege los datos de aplicación mediante registros autenticados. Su procesamiento depende de secretos de tráfico, claves y números de secuencia separados por dirección; además, el protocolo permite actualizar las claves durante una conexión @rfc8446. Por ello, preservar el transporte no basta para continuar una comunicación cifrada. El destino necesita un estado criptográfico coherente con los registros ya procesados y pendientes. La reanudación de sesión TLS, que participa en un nuevo establecimiento, no equivale a continuar la conexión activa en el mismo punto.

  HTTP/1.1 define conexiones persistentes y reglas de delimitación de mensajes mediante mecanismos como `Content-Length` y codificación fragmentada. También establece restricciones sobre el orden de respuestas y el uso de conexiones persistentes @rfc9112. El estado relevante depende del momento de la transferencia: puede incluir bytes recibidos, avance del análisis de cabeceras o cuerpo y respuestas pendientes. El protocolo especifica el comportamiento observable, pero la representación interna pertenece a cada implementación.

  Capybara ejemplificó esta dependencia con un framework HTTP mínimo que exporta solicitudes parcialmente recibidas y con un gestor basado en TLSe que restaura el contexto TLS sin repetir el establecimiento @capybara. Estos casos muestran la necesidad de interfaces de exportación e importación en las capas que mantienen estado. HTTP/2 incorpora flujos concurrentes y control de flujo por conexión y por flujo, además del procesamiento de bloques de cabeceras @rfc9113; su conservación introduce requisitos adicionales respecto de HTTP/1.1.

  #heading-level-3("1.5.4", "Migración de conexiones en trabajos previos")

  Yu y sus colaboradores propusieron COAT para migración de contenedores con estado en el borde de la red. Su arquitectura combinó CRIU y Podman con redes superpuestas, Open vSwitch y VXLAN para conservar conectividad al mover servicios entre hosts @coat. El trabajo aborda tanto la restauración del estado como las condiciones de direccionamiento y alcance de red. Su evaluación corresponde a migración de contenedores; no presenta adaptadores de una biblioteca Rust para actualizar selectivamente el estado TLS 1.3 y HTTP/1.1 entre binarios.

  Hayakawa y sus colaboradores presentaron PRISM para disminuir el trabajo de los frontends en almacenamiento de objetos. El frontend analiza una petición y entrega al backend seleccionado la conexión y el estado necesario para responder directamente al cliente. La implementación empleó `TCP_REPAIR`, TLSe, TLS del núcleo y un conmutador que modifica el encaminamiento del flujo @prism. Su protocolo coordina la transferencia en límites de peticiones y contempla estado TCP, TLS y de aplicación. El objetivo evaluado es evitar el costo de reenviar datos a través del frontend, no retirar versiones antiguas de un proxy durante su actualización.

  Choi y sus colaboradores presentaron Capybara para redistribuir conexiones establecidas cuando la carga entre servidores es desigual. El sistema combinó un conmutador programable, una pila de red que evita el procesamiento del núcleo y un protocolo de migración en dos fases. Su interfaz permite registrar gestores del estado asociado a cada conexión @capybara. La evaluación estudia balanceo dinámico entre servidores y su efecto sobre rendimiento y latencia. Su soporte de HTTP y TLS constituye un antecedente directo de conservación de estado por capas, aunque utiliza una infraestructura diferente de los sockets Linux compartidos entre procesos locales.

  En un contexto más próximo a la actualización de proxies, MOSN documenta transferencia de descriptores, búferes de lectura y estado TLS mediante sockets de dominio Unix. El procedimiento suspende escrituras para evitar que dos procesos alteren simultáneamente la comunicación y contempla el envío de respuestas residuales desde la instancia anterior hacia la nueva @mosn-upgrade. La documentación vincula el soporte de migración con las propiedades del protocolo y de su implementación. Por tanto, este antecedente no permite asumir compatibilidad automática con cualquier biblioteca TLS ni con cualquier estado de HTTP.

  #heading-level-3("1.5.5", "Consistencia y evaluación de la transferencia")

  Los mecanismos descritos requieren coordinar el cambio de responsable del flujo. MOSN evita escrituras simultáneas durante la transición; PRISM coordina la restauración con reglas de red; Capybara exige una instantánea consistente del estado local de aplicación @mosn-upgrade @prism @capybara. La consistencia incluye tanto los bytes del transporte como la interpretación que mantienen las capas superiores. Una migración del socket puede resultar insuficiente si deja fuera datos ya consumidos por un analizador o pendientes en un búfer de usuario.

  Las evaluaciones publicadas utilizan métricas acordes con sus fines: COAT examina la duración de las etapas de migración de contenedores; PRISM mide costo del traspaso, rendimiento y utilización de recursos; Capybara analiza percentiles altos de latencia y rendimiento bajo redistribución de carga @coat @prism @capybara. Sus resultados corresponden a configuraciones experimentales distintas y no son umbrales directamente transferibles a una biblioteca local. En conjunto, estos antecedentes fundamentan la necesidad de documentar el estado conservado, las condiciones de transferencia y el costo observable de mantener la comunicación.
]
