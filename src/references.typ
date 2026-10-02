// IEEE bibliography renderer. Keep this call at the end of thesis.typ.
#let ieee-references() = bibliography(
  "../references.bib",
  style: "ieee",
  title: "Referencias",
)
