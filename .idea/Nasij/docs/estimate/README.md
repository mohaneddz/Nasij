# Nasij Estimate Documents

This folder contains the research-backed strategy and estimate package for Nasij, plus a script to convert markdown documents to PDF.

## Folder Layout

```text
estimate/
  assumptions.md
  bmc.md
  business-plan.md
  empathy-card.md
  glossary.md
  pestel.md
  porter.md
  services.md
  sources.md
  README.md
  scripts/
    build_pdfs.ps1
  pdf/
    *.pdf
```

## Document Set

Core publishable docs (default PDF build target):

- `business-plan.md`
- `bmc.md`
- `porter.md`
- `pestel.md`
- `empathy-card.md`

Supporting docs:

- `services.md`
- `assumptions.md`
- `sources.md`
- `glossary.md`

## Citation Contract

- External and factual claims use source citations: `[Sxx](./sources.md#sxx)`.
- Model and forecast values use assumptions citations: `[Axx](./assumptions.md#axx)`.
- Every `Sxx` must exist in `sources.md`; every `Axx` must exist in `assumptions.md`.

## PDF Build Script

Script path:

- `scripts/build_pdfs.ps1`

Dependencies:

- Microsoft Word desktop (COM automation)
- Python with `markdown` package (`pip install markdown`)

Stable interface:

```powershell
.\build_pdfs.ps1 -InputDir <path> -OutputDir <path> [-AllMarkdown] [-Files <list>]
```

### Usage Examples

Run from `nasij/docs/estimate/scripts`.

1) Default conversion (core 5 docs to `../pdf`):

```powershell
.\build_pdfs.ps1
```

2) Convert all markdown files in estimate folder:

```powershell
.\build_pdfs.ps1 -AllMarkdown
```

3) Convert specific files:

```powershell
.\build_pdfs.ps1 -Files business-plan,porter,sources
```

4) Custom input/output paths:

```powershell
.\build_pdfs.ps1 -InputDir "D:\path\to\estimate" -OutputDir "D:\path\to\estimate\pdf"
```

## Naming Rules

- Keep markdown filenames lowercase with hyphen separators.
- PDF filenames follow markdown basenames exactly.
  - Example: `business-plan.md` -> `business-plan.pdf`

## Troubleshooting

- **Word COM unavailable**:
  - Install Microsoft Word desktop edition and retry.
  - The script fails fast with a clear error when COM cannot be instantiated.
- **Python markdown package missing**:
  - Install dependency with `python -m pip install markdown`.
  - The script fails with a conversion error if markdown rendering is unavailable.
- **Missing core file error**:
  - Ensure all default core docs exist in the input directory.
- **Wrong output location**:
  - Pass an explicit `-OutputDir` and verify the path exists or is creatable.
- **Formatting differences across machines**:
  - Word rendering can vary by installed fonts and Office version; keep style checks in final QA.
