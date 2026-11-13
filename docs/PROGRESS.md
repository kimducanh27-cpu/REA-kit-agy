# PROGRESS — REA-kit-agy

- Last updated: 2026-11-13
- Overall status: P00 IN PROGRESS
- Repository branch: main
- Previous commit: c0b439d373571e24af4e44fb54470654c37ba4c2

## 2026-11-13 — P00 deeper source audit

### Completed in this session
- Inspected REA setup planning, approval, dry-run, client configuration transaction, recovery backup, skills validation, doctor workflow, interactive setup, and filesystem regression tests.
- Confirmed REA builds a setup plan, exposes dry-run, asks for approval, and only then applies selected actions.
- Confirmed REA recovery backup uses exclusive copy behavior, preserves original bytes, and verifies the resulting backup.
- Confirmed REA serializes configuration transactions per resolved path.
- Confirmed REA Doctor is a read-only structured readiness workflow.
- Reviewed current official customization documentation for Antigravity, Claude Code, Cursor, and OpenCode.
- Recorded the cross-agent discovery matrix and adapter implications in AGENT_COMPATIBILITY.md.
- Researched candidate document-processing projects and documented capabilities, licenses, maintenance signals, and limitations in FILE_WORKFLOWS_RESEARCH.md.
- Expanded SOURCE_AUDIT.md with exact source mappings and file-level reuse boundaries.

### Evidence-backed findings
- Antigravity, Cursor, and OpenCode document project skill discovery from .agents/skills/.
- Claude Code currently documents project skills in .claude/skills/ and has conditional AGENTS.md behavior; a CLAUDE.md @AGENTS.md import is an official compatibility mechanism.
- MarkItDown is a broad candidate for extracting mixed documents into Markdown for AI analysis, but its README says it is not intended for high-fidelity document conversion for human consumption and includes input/network security cautions.
- pypdf 7.0.1 was released on 2026-11-10; pypdf documentation warns scanned/image-only PDFs may yield little or no extracted text.
- python-docx 1.2.0 is a candidate for DOCX creation and controlled updates, not legacy DOC.
- openpyxl official documentation recommends defusedxml for certain XML attack protections; inspected PyPI metadata shows an older latest release date of 2024-06-28, so maintenance freshness is a concern.
- No candidate dependency has been selected or installed.

### Not completed
- No product source code or executable kit functionality has been created.
- No OCR engine has been selected.
- No live agent integration test has been performed.
- No representative office-document fixture benchmark has run.
- No final dependency stack or implementation architecture has been approved.

### Next work
1. Research OCR candidates with Vietnamese support, local processing, licensing, packaging, and maintenance status.
2. Compare extraction and editing candidates against representative public/synthetic PDF, DOCX, XLSX, and scanned-PDF fixtures.
3. Confirm the exact P00 implementation boundary and unresolved choices with the owner.
4. Only then begin P01 Workspace Foundation.

## 2026-11-13 — Initial repository baseline

- Confirmed destination repository: kimducanh27-cpu/REA-kit-agy.
- Created the six mandatory context files plus PLAN.md, HANDOFF.md, AI_UPDATE_PROMPT.md, and SOURCE_AUDIT.md.
- Initial source inspection found REA as an implementation reference and Craft Anything as high-level UX observation only.
- No product implementation was performed.


## 2026-11-13 — P00 OCR research

### Completed in this session
- Verified the preceding source-audit commit remains on main and the context docs are present.
- Researched Vietnamese OCR candidates from current upstream repositories and official documentation: RapidOCR, Tesseract/tessdata_best, PaddleOCR, Docling, and EasyOCR.
- Inspected exact source files and licenses for RapidOCR's model registry/model-license notice, EasyOCR's language configuration, Tesseract's Vietnamese traineddata, PaddleOCR's language matrix, and Docling's package metadata.
- Added OCR_RESEARCH.md with inspected revisions, release versions, license boundaries, Windows/offline behavior, candidate ordering, and test measures.
- Updated FILE_WORKFLOWS_RESEARCH.md, SOURCE_AUDIT.md, TASKS.md, and HANDOFF.md.

### Evidence-backed findings
- RapidOCR v3.10.0 (2026-10-08) has a PP-OCRv6 multilingual route including vi; the official model registry lists Vietnamese. Its model-license notice says registered model artifacts are Apache-2.0, while dictionaries and fonts are outside that declaration.
- RapidOCR supports local model paths. Its installation guide describes a roughly 27.2 MB package and says ONNX Runtime must be installed separately for the default ONNX engine from v2.0.6 onward.
- Tesseract 5.5.4 was released 2026-10-28; the official tessdata_best repository contains vie.traineddata (12,435,550 bytes). Windows installation guidance points to UB Mannheim installers and separate language-data placement.
- PaddleOCR v3.7.0 supports Vietnamese in PP-OCRv5 and PP-OCRv6 language tables and documents Windows/local model use.
- Docling v2.150.0 (2026-11-10) is MIT-licensed, declares Python >=3.10 and Windows support, and documents pluggable OCR engines including RapidOCR, EasyOCR, and Tesseract.
- EasyOCR source includes vi in its Latin language list and supports CPU-only mode, but the latest stable release inspected is v1.7.2 from 2024-09-24; Windows setup requires separate PyTorch/torchvision installation.
- No engine has been benchmarked or selected.

### Not completed
- No OCR package has been installed.
- No model weights or third-party binaries have been added to the repository.
- No OCR accuracy, throughput, or memory comparison has run.
- No Windows installation test has run.
- No dependency set or P00 implementation boundary has been approved.

### Next work
1. Prepare public/synthetic Vietnamese scan fixtures with verified ground-truth text and representative tables.
2. Compare RapidOCR PP-OCRv6 and Tesseract vie first; include Docling as a document-level pipeline comparison.
3. Measure CER/WER, reading order/table fidelity, CPU/memory, offline repeatability, and Windows packaging effort.
4. Complete P00 recommendations and obtain owner approval before P01 implementation.


## 2026-11-13 — Product-focus correction: OCR is optional, not core

The owner asked why OCR had become the next focus. Clarification:
- OCR is only needed when extracting text from image-only/scanned PDFs or images; ordinary text PDFs do not normally require OCR.
- The project is a Non-Tech Workspace Bootstrap Kit, not an OCR/document-conversion product.
- OCR and file-processing research from earlier sessions is retained as optional future reference, but it must not drive the core plan or block workspace bootstrap.
- P00 is refocused on REA-derived bootstrap/install mechanisms, Antigravity-first workspace setup, other-agent adapters, safety/approval/backup/health checks, and defining the minimum useful v1.
- No OCR engine or document-processing dependency has been selected or installed.
