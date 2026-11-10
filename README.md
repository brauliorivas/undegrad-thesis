# Typst thesis template

This project implements the Materia Integradora format for FIMCP - ESPOL and
contains the thesis topic **Migración de conexiones TCP en proxies balanceadores
de carga**.

From the repository root, compile the PDF with Typst:

```sh
mkdir -p output
typst compile thesis.typ output/thesis.pdf
```

Fill in the placeholders in `src/data.typ`. The main file only arranges pages;
the editable sections are in `src/`.

The template uses Liberation Serif at 12 pt. This installed font has regular,
bold, italic, and bold italic faces. It is a free substitute for Times New Roman.

## PlantUML diagrams

The Chapter 2 diagrams live in `src/figures/diagrams/`. Each `.puml` source has a
matching `.svg` that Typst embeds in the PDF. Commit both files when changing
a diagram. Typst compiles the thesis using the checked-in SVGs.

To regenerate the SVGs from the repository root, use Java, Graphviz (`dot`),
and the PlantUML JAR. Adjust the JAR path to match your installation.

```sh
java -Djava.awt.headless=true -jar ~/plantuml-mit-1.2026.9.jar \
  -charset UTF-8 -failfast2 -nometadata -tsvg src/figures/diagrams/*.puml
```

Pass a single `.puml` path to export just that diagram. PlantUML writes the
SVG next to its source. Run the Typst command above to rebuild the PDF.

## IEEE citations

Add BibTeX entries to `references.bib`, then cite a source in Spanish content
using `@citation-key`, for example `@rfc9293`. `#ieee-references()` at the end of `thesis.typ` renders the bibliography in IEEE style with the heading `Referencias`.
