#import "style.typ": heading-level-1, heading-level-2, heading-level-3, heading-level-4, heading-level-5

#let chapter-one() = [
  #heading-level-1("CAPÍTULO 1")

  #heading-level-2("1.1", "Introducción")
  [Redacte aquí la introducción. Presente el contexto general, antecedentes, tendencias o datos que evidencien la situación; explique la relevancia actual del tema, su pertinencia académica y formativa, su vinculación con la sociedad o el sector productivo, el alcance general y la organización del informe. Use principalmente presente; emplee pasado para antecedentes y futuro al describir la organización del informe.]

  #heading-level-2("1.2", "Descripción del problema")
  [Describa con detalle lo que se resolverá: requerimientos, restricciones, variables de interés y las posibilidades de observación, medición o análisis. Si la organización cliente no autorizó el uso de su nombre, descríbala de manera general. Redacte principalmente en presente.]

  #heading-level-2("1.3", "Justificación del problema")
  [Explique con claridad qué se resolverá y por qué es importante hacerlo.]

  #heading-level-2("1.4", "Objetivos")
  [Los objetivos deben responder qué se hará y para qué se hará. Redáctelos con verbos activos en infinitivo y con una única interpretación.]

  #heading-level-3("1.4.1", "Objetivo general")
  [Escriba la meta general o global del proyecto.]

  #heading-level-3("1.4.2", "Objetivos específicos")
  [Enumere los grandes pasos o etapas que construyen el objetivo general. En un proyecto multidisciplinario, identifique entre paréntesis la carrera responsable de cada objetivo.]

  // APA run-in heading usage examples:
  // #heading-level-4("Subtema", [El texto continúa en la misma línea.])
  // #heading-level-5("Detalle", [El texto continúa en la misma línea.])
]
