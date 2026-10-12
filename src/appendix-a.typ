#import "style.typ": heading-level-2

#let search-method() = [
  #heading(level: 1, numbering: none)[APÉNDICE A] <metodo-busqueda>
  #heading-level-2("A.1", "Método de búsqueda de antecedentes")

  La revisión documental se realizó y amplió el 12 de octubre de 2026. Su propósito fue identificar mecanismos de continuidad y migración que permitan valorar las tres propiedades del problema: transferencia local de conexiones aceptadas sobre Linux, conservación de TLS 1.3 y HTTP/1.1 en ambos lados de un #emph[proxy] e integración mediante una biblioteca Rust independiente de una aplicación particular.

  Se consultaron artículos de USENIX y ACM, publicaciones de sus autores, documentación oficial de NGINX, HAProxy, Envoy y MOSN, repositorios públicos y documentación de componentes Rust. Los trabajos sobre migración y actualización incluyeron SockMi, CRIU/libsoccr, COAT, Kitsune, OpenNF, HA/TCP, PRISM, XO y Capybara. Las fuentes individuales y las versiones de documentación utilizadas figuran en las referencias.

  Las consultas combinaron los términos «TCP connection migration», «TLS state migration», «HTTP state migration», «hot restart», «graceful restart» y «dynamic software updating». En GitHub se utilizaron `"hot restart" language:Rust` y `"connection migration" language:Rust`; se complementaron con búsquedas web de componentes de crates.io. Se revisaron ecdysis, listenfd y Hot Restart Proxy; de este último se consultaron README, `src/handler.rs` y `src/server.rs` en la revisión identificada en su referencia. La revisión de interfaces de protocolos comprendió rustls, Hyper y kTLS.

  Para la Tabla 1.2 se incluyeron mecanismos con una fuente primaria que describiera al menos una operación pertinente: herencia de escucha, transferencia de conexiones aceptadas, captura del transporte o conservación del estado TLS/HTTP. Se registraron unidad de transferencia, entorno, estado documentado y forma de reutilización. Un estado no evaluado se distinguió de una imposibilidad técnica. Los sistemas de redistribución entre servidores se conservaron como antecedentes, aunque su escenario difiera de la actualización local entre versiones.

  Se excluyeron como equivalentes directos las propuestas centradas únicamente en cambios de dirección de QUIC, los mecanismos de reconexión y los trabajos sin evidencia primaria suficiente para caracterizar su estado transferido. Las mediciones de la Tabla 1.3 se seleccionaron con su operación y entorno; no se normalizaron ni se utilizaron para ordenar los sistemas por velocidad.

  En el repositorio de ESPOL se buscaron «migración de conexiones», «migración conexiones TCP actualización proxy» y «TCP proxy actualización», mediante consultas web restringidas a `dspace.espol.edu.ec`. No se identificó un trabajo directamente equivalente. Se encontró un trabajo sobre monitoreo TCP/IP, cuyo objeto es capturar y observar tráfico, por lo que no se incorporó como antecedente de migración. Esta búsqueda institucional no representa una revisión de todos los repositorios nacionales.

  La búsqueda es documental y acotada, sin pretensión de revisión sistemática exhaustiva. Los registros de componentes y los resultados indexados pueden omitir implementaciones. La brecha se establece respecto de las alternativas caracterizadas en la Tabla 1.2; la viabilidad de las dependencias y los puntos seguros se resolverá mediante pruebas de exportación y restauración en el diseño.
]
