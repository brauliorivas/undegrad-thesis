# Revisión del capítulo 1

Fecha de revisión: 12 de octubre de 2026. Base: `main` en `0ac7ad07635aceffaae4eec1323782e1448736b3`.

El plan recibido se aplicó como guía editorial. El capítulo presenta el problema, el aporte y los criterios de aceptación; el diseño detallado y la selección de dependencias corresponden al capítulo 2.

## Alcance acordado

- Biblioteca en Rust integrada en el código del proxy, para actualizaciones cooperativas entre procesos de una misma máquina Linux.
- Entrega principal: ambas conexiones y su asociación, TLS 1.3 en ambos lados y HTTP/1.1. El autor confirmó expresamente TLS con el cliente y con el servidor de destino.
- Un proxy de demostración con tres modos comparables: migración, drenaje y ejecución sin actualización.
- Compatibilidad limitada a las bibliotecas adaptadas, los estados admitidos y las versiones evaluadas.
- HTTP/2 es una extensión opcional. La continuidad exige conservar datos y conexiones; admite una pausa que se mide.

## Cambios aplicados

| Apartado | Cambio |
| --- | --- |
| 1.1 | Contexto centrado en comunicaciones prolongadas y mantenimiento; vínculo con asignaturas concretas y recorrido de capítulos. |
| 1.2 | Problema como componente reutilizable, dos extremos TLS, puntos de integración y puntos seguros definidos una vez, restricciones y criterios de aceptación. |
| 1.3 | Brecha acotada a las fuentes revisadas; contribución separada en biblioteca, adaptaciones y evaluación. |
| 1.4 | Cuatro objetivos verificables, con finalidad y métricas de evaluación. |
| 1.5 | Orden desde proxies y drenaje hasta estado, migración y funciones de red; fundamentos de descriptores, TLS 1.3 y HTTP/1.1. |
| Elementos visuales | Dos figuras vectoriales y tres tablas. Las mediciones se separan de la comparación funcional para conservar su contexto experimental. |
| Formato | Elementos nativos de Typst para índices y numeración; títulos de tablas y figuras en negrita/cursiva, notas a la izquierda y tablas con líneas horizontales. |
| Referencias | Fuentes primarias adicionales, sustitución del hilo de Fly.io y fechas de publicación de artículos web visibles en IEEE. |

La sección de síntesis 1.5.5 permanece eliminada, conforme a la indicación anterior del autor. La columna de reutilización describe bibliotecas, interfaces y dependencia de plataformas; una respuesta binaria habría ocultado que SockMi, libsoccr, PRISM y Capybara sí ofrecen componentes o interfaces reutilizables.

## Revisión documental acotada

Se buscó un componente que reúna **todos** estos criterios: biblioteca Rust, conexiones aceptadas de ambos lados de un proxy, sockets de Linux, actualización local entre versiones y restauración de TLS 1.3/HTTP/1.1. La búsqueda es reproducible por sus consultas y fuentes, pero no constituye una revisión sistemática exhaustiva ni una prueba de inexistencia.

| Consulta o conjunto | Comprobación y resultado |
| --- | --- |
| GitHub: `"hot restart" language:Rust` y `"connection migration" language:Rust` | Se examinó el README y `src/handler.rs`/`src/server.rs` de [Hot Restart Proxy](https://github.com/conorbros/hot-restart-proxy), que pasa pares TCP pero no incorpora TLS ni procesamiento HTTP. Los resultados QUIC se descartaron por tratar otro problema. |
| Componentes Rust y registros | Se revisaron [ecdysis](https://github.com/cloudflare/ecdysis), [shellflip](https://github.com/cloudflare/shellflip), [listenfd](https://docs.rs/listenfd/latest/listenfd/), y búsquedas web de `hot restart`/`connection migration` en crates.io. Sus páginas requieren JavaScript, por lo que no se afirma haber inspeccionado todo el registro. |
| Proxies de producción | Se consultaron [NGINX](https://nginx.org/en/docs/control.html), [HAProxy 3.2](https://www.haproxy.org/download/3.2/doc/management.txt) y [Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart). Se distinguió herencia de escucha y drenaje de transferencia de conexiones aceptadas. |
| Migración y captura | Se contrastaron MOSN, SockMi, CRIU/libsoccr, COAT, Kitsune, OpenNF, HA/TCP, PRISM, XO y Capybara con sus artículos, documentación o código primario, referenciados en `references.bib`. |
| Bibliotecas de protocolos | [rustls](https://docs.rs/rustls/0.23.35/rustls/struct.ExtractedSecrets.html) documenta extracción para kTLS; [Hyper](https://docs.rs/hyper/latest/hyper/server/conn/http1/struct.Connection.html) condiciona `into_parts` al término del procesamiento. Estas lecturas no prueban viabilidad de restauración. |
| ESPOL | Búsquedas `site.dspace.espol.edu.ec migración conexiones TCP actualización proxy` y `site.dspace.espol.edu.ec "migración de conexiones"`. No se identificó un antecedente directamente equivalente en los resultados examinados. El [monitoreador TCP/IP de 1998](https://www.dspace.espol.edu.ec/handle/123456789/3167) trata captura y monitoreo, por lo que no se incorporó como antecedente de migración. |

La brecha se formula sobre ese conjunto, reconociendo que Capybara ya integra un componente Rust y exportación/importación de estado. La distinción del proyecto se apoya en su escenario y contrato de integración, no en afirmar que nadie haya migrado conexiones o escrito bibliotecas antes.

## Decisiones de diseño pendientes

1. Seleccionar TLS y HTTP después de una prueba corta de exportación **y restauración**, cubriendo roles cliente y servidor TLS. rustls y Hyper aparecen como ejemplos documentados, no como dependencias seleccionadas.
2. Determinar puntos seguros y comprobar si se pueden migrar mensajes HTTP en curso. Si solo se admiten límites entre mensajes, medir cómo las transferencias largas condicionan la espera y el retiro; ajustar el alcance antes de presentar esa propiedad como resultado.
3. Definir la compatibilidad de estado entre versiones, la confirmación del traspaso y el tratamiento de rechazos. La validación debe distinguir actualizar código de ejecutar otra instancia idéntica.

No se ejecutaron estas pruebas de viabilidad ni se implementó la biblioteca en este PR editorial. Las restricciones aparecen en 1.2 en prosa, sin marcadores provisionales.

## Correspondencia con capítulos posteriores

| Objetivo | Evidencia prevista | Conclusión en capítulo 4 |
| --- | --- | --- |
| Identificar estado y condiciones | Capítulo 2: inventario y puntos seguros de cada adaptador. | Condiciones y limitaciones observadas. |
| Diseñar biblioteca e intercambio | Capítulo 2: arquitectura, interfaz y compatibilidad. | Consistencia y alcance del diseño. |
| Implementar e integrar | Capítulos 2 y 3: componentes, cambios al proxy y prueba completa. | Viabilidad de la integración. |
| Evaluar | Capítulo 3: continuidad, integridad, costos y esfuerzo frente a las referencias. | Efectividad y límites respaldados por mediciones. |

## Verificación

La compilación completa se comprobó con Typst 0.15.0. El capítulo contiene aproximadamente 3.050 palabras, incluidas tablas, títulos y texto de los diagramas, por debajo del máximo de 3.500. La revisión del PDF comprobó referencias e índices, márgenes de 2,54 cm, cuerpo de 12 pt, interlineado de 24 pt y numeración de tablas/figuras. La plantilla usa Liberation Serif, como documenta el README.

Los complementarios y el título conservan tareas pendientes del proyecto: código, resumen/abstract, abreviaturas, simbología y revisión del título. Su contenido requiere decisiones o resultados posteriores y no forma parte de la reescritura del capítulo.
