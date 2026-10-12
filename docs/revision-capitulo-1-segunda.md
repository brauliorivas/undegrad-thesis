# Segunda revisión del capítulo 1

Fecha: 12 de octubre de 2026. Base: `main`, commit `1f111160161695e25cb223fd4ee0264d984b9ad8` (PR #2 integrado).

## Cambios

- Reduce repeticiones en 1.2, 1.3 y 1.5; concentra la caracterización de los mecanismos en la Tabla 1.2 y remite a ella desde la justificación.
- Añade el Apéndice A con fecha, fuentes, consultas, criterios de inclusión y límites de la revisión documental. Incluye la búsqueda institucional en ESPOL sin extrapolarla a todos los repositorios nacionales.
- Separa asociación y retiro en la Tabla 1.1. Usa proceso anterior/proceso nuevo para el traspaso y reserva destino para el servidor remoto.
- Define el núcleo de coordinación y el papel de los adaptadores. Conserva TCP, TLS 1.3 en ambos lados y HTTP/1.1 como entrega principal; HTTP/2 sigue siendo una extensión opcional.
- Justifica Rust por la administración de descriptores con `OwnedFd`, sin atribuir al compilador la coordinación entre procesos.
- Define TLSe, Demikernel y Redis; conserva la advertencia sobre unidades y entornos experimentales distintos.
- Identifica versiones de documentación y el commit de Hot Restart Proxy en las referencias visibles. Conserva fechas de consulta reales: MOSN se consultó el 5 de octubre; no se cambia su fecha sin una nueva lectura.
- Corrige la nota de la Figura 1.2 y la separación entre asignaturas. El punto y coma de 1.5.2 ya estaba presente en la fuente.

## Adaptaciones del plan

Se sustituyó la propuesta de citar un promedio de explotación de cinco días por los datos de vulnerabilidades explotadas después de disponer de un parche: 29 % en una semana y 56 % en un mes, sobre 41 casos. El promedio propuesto incluye vulnerabilidades de día cero y excluye 15 valores atípicos; con ellos asciende a 47 días. Las cifras seleccionadas se relacionan más directamente con la oportunidad de instalar correcciones. Se presentan como contexto general de seguridad, sin cuantificar el riesgo de proxies.

Se mantuvo BibTeX y el procesador bibliográfico de Typst con estilo IEEE. Renumerar manualmente o añadir otro gestor no mejora este proyecto: la compilación asigna números por primera aparición. La revisión verificó las 30 referencias, sin saltos, y la correspondencia de las citas.

El apéndice registra la revisión previa y su ampliación actual. Las búsquedas no prueban inexistencia de alternativas. Las dependencias TLS/HTTP y los puntos seguros continúan pendientes de pruebas de viabilidad; no se presentan decisiones de diseño ni resultados experimentales inexistentes.

## Validación

- Compilación completa con Typst 0.15.0 y revisión visual de las páginas modificadas, tablas, referencias y apéndice.
- Capítulo 1: 2.873 palabras por extracción del PDF, incluidos títulos, tablas, notas, diagramas y números de página; referencias y apéndice excluidos. Inferior al límite de 3.500.
- Dos figuras y tres tablas conservan índices y referencias. Apéndice A figura en el índice y los enlaces desde el capítulo funcionan.
- Márgenes horizontales comprobados sobre el PDF; cuerpo Liberation Serif 12 pt, interlineado y alineación heredados de la plantilla. Se conserva el uso de cursivas en proxy, kernel, socket y software.
- Comprobación de espacios y errores de parche con `git diff --check`.

No se modifican título, resumen, abstract ni complementarios que el plan deja para después.
