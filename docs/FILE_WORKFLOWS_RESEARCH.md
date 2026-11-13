# FILE WORKFLOWS RESEARCH — REA-kit-agy

- Research date: 2026-11-13
- Status: CANDIDATE SURVEY / NO DEPENDENCIES APPROVED
- Purpose: identify real document-processing projects before selecting implementation tools.

## 1. Decision rule

The kit needs separate capabilities for:
- Reading/extracting content for AI analysis.
- Creating new documents and spreadsheets.
- Editing existing documents while preserving layout and structure.
- OCR for scanned pages and images.
- Validating generated deliverables.

Do not assume one parser solves all five. The candidates below are research references only. No package has been installed or tested in REA-kit-agy.

## 2. Candidate shortlist

### 2.1 Microsoft MarkItDown — broad extraction to Markdown

Source: https://github.com/microsoft/markitdown
Inspected main commit: ed178952a6672abdfd35b5f9e76a80b6cefc086e
License: MIT
Inspected main-branch commit date: 2026-11-07.

Verified capabilities and limits:
- Converts PDF, PowerPoint, Word, Excel, images, HTML, text formats, ZIP and other inputs into Markdown for LLM/text analysis.
- Focuses on retaining useful structure such as headings, lists, tables and links.
- Supports optional format-specific dependencies.
- Its README explicitly says the output is intended for text analysis and may not be suitable for high-fidelity document conversion for human consumption.
- Some image captioning and audio transcription features rely on web-hosted services.
- Security guidance says conversion runs with the current process's privileges. Untrusted inputs, paths, URI schemes and network destinations must be restricted; prefer the narrowest conversion API.
- GitHub Releases showed v0.1.8b1 as a prerelease and v0.1.4 as a stable release in the inspected results. Recheck the stable release before pinning.

Candidate role:
- RESEARCHED CANDIDATE for read-only extraction and summarization across mixed file formats.
- NOT a final layout-preserving document converter.
- Do not enable cloud captioning, transcription, or remote URI fetching by default.

### 2.2 pypdf — PDF extraction and structural operations

Source: https://github.com/py-pdf/pypdf
Inspected main commit: 77c9a418421b6a783b9e7795973e778f3a10fb9d
License: BSD-3-Clause.
PyPI reported stable version 7.0.1 released 2026-11-10 at research time.

Verified capabilities:
- Pure-Python library for extracting text and metadata, splitting, merging, cropping, transforming pages, and handling PDF features.
- Documentation provides a layout-oriented text extraction mode.
- Documentation warns that extracting a page parses its full content stream and unusually large streams can require substantial memory.
- Scanned/image-only PDFs may return little or no text. OCR is a separate capability.

Candidate role:
- RESEARCHED CANDIDATE for local PDF text extraction and basic structural operations.
- OCR and visual-layout interpretation remain separate RESEARCH NEEDED items.
- Test malformed, encrypted, image-only, table-heavy, and large PDFs before selection.

### 2.3 python-docx — DOCX reading and generation

Source: https://github.com/python-openxml/python-docx
Inspected master commit: e45454602b53e8e572b179ccf1c91093ec9f4ed7
License: MIT.
Inspected official documentation version: 1.2.0; inspected release commit date: 2025-06-16.

Verified capabilities:
- Reads, creates, and updates Microsoft Word 2007+ DOCX documents.
- Supports common paragraphs, headings, lists, tables, images, and page breaks.
- Does not target legacy binary DOC files.

Candidate role:
- RESEARCHED CANDIDATE for creating new DOCX reports and controlled edits to DOCX.
- Do not assume complete support for every Word feature or perfect layout preservation.
- Test headers, footers, fields, footnotes, sections, embedded objects, tables, images, and unsupported XML parts.

### 2.4 openpyxl — XLSX/XLSM workbook operations

Source: https://openpyxl.readthedocs.io/en/stable/
Official documentation identifies its source project at https://foss.heptapod.net/openpyxl/openpyxl.
Inspected documentation version: 3.1.3; documentation generation date shown as 2024-05-29.
License shown by official documentation: MIT/Expat.
PyPI metadata inspected at research time reports latest release date 2024-06-28.
The GitHub repository ericgazoni/openpyxl has an old inspected master commit dated 2014-03-08; do not treat that GitHub repository as current upstream.

Verified capabilities and limits:
- Reads and writes Excel 2010+ XLSX, XLSM, XLTX, and XLTM.
- Documentation warns that openpyxl does not by default guard against XML quadratic blowup or billion-laughs attacks and recommends defusedxml as a mitigation.
- It is not an Excel calculation engine.

Candidate role:
- RESEARCHED CANDIDATE for bounded workbook edits and report generation.
- Release freshness is a concern to review before selection.
- Test formulas, macros, external links, charts, pivot tables, data validation, conditional formatting, images, named ranges, and workbook protection. Do not assume a load/save round trip preserves every Excel feature.

### 2.5 pandas — spreadsheet analysis, not workbook fidelity

Source: https://pandas.pydata.org/docs/reference/api/pandas.read_excel.html
Inspected documentation version: 3.1.1.

Verified capabilities:
- read_excel supports multiple spreadsheet formats through format-specific engines including openpyxl, calamine, odf, pyxlsb, and xlrd.
- DataFrame structures are useful for tabular cleaning, aggregation, and analysis.
- DataFrames can be exported to Excel through to_excel.

Candidate role:
- RESEARCHED CANDIDATE for table cleaning, aggregation, and analysis.
- Do not assume DataFrame round-tripping preserves workbook formatting, formulas, macros, charts, or other workbook objects.
- Review engine dependencies and licenses before selecting.

## 3. Initial workflow mapping

| User workflow | Candidate sources | Current finding |
|---|---|---|
| Summarize mixed PDF/DOCX/XLSX/PPTX | MarkItDown; specialized parsers as fallback | Candidate for text extraction only; layout fidelity not guaranteed |
| Extract text from searchable PDF | pypdf; MarkItDown | Candidate; test memory and extraction quality |
| Read scanned PDF | OCR engine still to be researched | NOT SELECTED |
| Create a new Word report | python-docx | Candidate; test formatting requirements |
| Edit an existing Word document | python-docx plus OOXML research if needed | NOT SELECTED; preservation risk |
| Clean and aggregate Excel data | pandas | Candidate for analysis |
| Edit workbook while retaining Excel features | openpyxl or another verified engine | NOT SELECTED; maintenance/compatibility concerns |
| CSV processing | Python standard library or pandas | Check whether standard library is sufficient before adding a dependency |
| Validate output | Format-specific parsers plus independent checks | Design and test strategy still needed |

## 4. Safety and implementation constraints

- Treat all documents as untrusted input.
- Restrict file paths to the intended workspace; do not allow a document to make a parser fetch arbitrary network URLs or read outside the workspace.
- Research file-size, page-count, archive-expansion, and processing-time limits before implementation.
- Do not execute macros, embedded scripts, or external links from source documents.
- Write results to new files; never overwrite the original source.
- Check output existence, readability, expected content, and format integrity.
- Report partial extraction when a parser cannot read an image-only page or unsupported feature.
- Do not claim high-fidelity format preservation until verified against representative files.

## 5. Open research items

1. Research OCR engines, licenses, Windows packaging, Vietnamese language support, and local/offline operation.
2. Evaluate PDF visual/layout extraction separately from plain text extraction.
3. Verify MarkItDown stable releases and optional dependency security before pinning.
4. Reassess openpyxl maintenance and alternatives before selecting an Excel writer.
5. Benchmark python-docx on documents containing headers, footers, tables, images, sections, and embedded objects.
6. Define a privacy-safe fixture corpus and expected-output tests. Do not commit the user's private documents.
7. Determine whether one bundled Python runtime or isolated skill environments is safer and simpler; no installer approach is selected.

## 6. Research conclusion

No dependency stack is approved. Current evidence supports a split between broad read-only extraction, specialized format editing, OCR, and independent output verification. The next step is a focused comparison and test plan, not immediate installation or code generation.


See [OCR_RESEARCH.md](OCR_RESEARCH.md) for the separate Vietnamese OCR and Windows packaging audit.
