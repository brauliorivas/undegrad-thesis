# Primer borrador del capítulo 2

Fecha: 4 de noviembre de 2026.

Se siguió la sección «2. Metodología» del formato de Materia Integradora: alternativas, selección, diseño conceptual y detallado, recursos, evaluación y consideraciones éticas. La redacción en pasado describe decisiones de diseño y planificación, sin afirmar que el prototipo o los experimentos estén terminados.

Se consultaron «TCP Migration Thesis», «Historias de usuario S1 T1» y «Añadir avances de tesis», además del capítulo 1 vigente. Se retomó la biblioteca integrada en ambos procesos, la comunicación directa y los adaptadores. Se mantuvo el alcance más reciente del capítulo 1: TLS 1.3 y HTTP/1.1 en ambos lados, incluidos cuerpos incompletos. La interfaz C y otras implementaciones quedaron como extensiones.

## Pendientes para la siguiente revisión

- Probar exportación y restauración de rustls y Hyper antes de fijar versiones y modificaciones. La selección del mecanismo de transferencia sí quedó definida.
- Concretar equipo, concurrencias, duración y repeticiones mediante una prueba piloto.
- Sustituir las previsiones de implementación y evaluación por el procedimiento realmente ejecutado cuando haya evidencia.

## Validación del borrador

- Compilación completa con `typst compile thesis.typ output/thesis.pdf`, sin advertencias.
- Revisión visual de las siete páginas del capítulo (12–18 de la tesis, 22–28 del PDF).
- 2129 palabras por extracción del PDF, incluidos títulos, tabla, figura y números de página. Límite: 3000.
- Tabla 2.1 y Figura 2.1 incluidas en los índices. Numeración del capítulo 1 conservada.
- Referencias nuevas: documentación primaria de CRIU, Tokio y Serde. Se reutilizaron las referencias pertinentes existentes.
