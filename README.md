# Typst thesis template

This project implements the Materia Integradora format for FIMCP - ESPOL and
contains the thesis topic **Migración de conexiones TCP en proxies balanceadores
de carga**.

Compile the PDF with:

```sh
typst compile thesis.typ output/thesis.pdf
```

Fill in the placeholders in `src/data.typ`. The main file only arranges pages;
the editable sections are in `src/`.

The template uses Liberation Serif at 12 pt. This installed font has regular,
bold, italic, and bold italic faces. It is a free substitute for Times New Roman.

## IEEE citations

Add BibTeX entries to `references.bib`, then cite a source in Spanish content
using `@citation-key`, for example `@rfc9293`. `#ieee-references()` at the end of `thesis.typ` renders the bibliography in IEEE style with the heading `Referencias`.
