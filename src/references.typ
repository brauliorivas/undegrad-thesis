// IEEE bibliography renderer. Keep this call at the end of thesis.typ.
#let ieee-references() = {
  // Match the quotation marks in the institutional IEEE examples.
  show "«": "“"
  show "»": "”"
  bibliography(
    "../references.bib",
    style: "ieee",
    title: "Referencias",
  )
}
