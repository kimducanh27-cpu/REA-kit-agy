# OCR RESEARCH — Vietnamese and local Windows use

- Research date: 2026-11-13
- Status: CANDIDATE AUDIT / NO ENGINE APPROVED
- Scope: OCR for Vietnamese scanned PDFs and images, with local processing and a manageable Windows installation.

## 1. Decision rule

Separate these capabilities:
- OCR engine: recognize text from page images.
- Document parser: preserve reading order, headings, tables, and page structure.
- PDF reader: extract embedded text from text-native PDFs.
- Output validator: verify extracted text and generated files.

OCR accuracy cannot be inferred from repository popularity or language support alone. No engine has been installed or benchmarked for this project.

## 2. Candidate comparison

### 2.1 RapidOCR 3.10.0 — priority prototype candidate

Sources:
- Repository: https://github.com/RapidAI/RapidOCR
- Inspected main commit: ae1d898295ecec19df7f4782f52949780e56d211 (2026-11-12)
- Latest release inspected: v3.10.0 (2026-10-08)
- License: Apache-2.0 for source code.
- Key files: python/rapidocr/default_models.yaml, python/MODEL_LICENSES.md, python/pyproject.toml.

Verified:
- Project README identifies Windows, Linux, and macOS support and describes local/offline deployment.
- Its default_models.yaml registers PP-OCRv6 multilingual routes with Vietnamese (vi), including tiny, small, and medium recognition model routes.
- Its MODEL_LICENSES.md states that every model registered in default_models.yaml is Apache-2.0. It explicitly excludes dictionaries and fonts from that model-license declaration; those resources retain their own applicable terms.
- Package metadata requires Python >=3.8 and <4, and lists classifiers through Python 3.13.
- From RapidOCR 3.10.0, ONNX Runtime is no longer an automatic dependency even though ONNX Runtime remains the default inference engine. The current installation guide shows installing rapidocr and onnxruntime together.
- The installation guide describes the package as about 27.2 MB, including three compact models for detection, orientation classification, and recognition.
- The local-model guide supports explicit local model paths, allowing models to be prepared before offline use.

Candidate role:
- RESEARCHED CANDIDATE / FIRST OCR PROTOTYPE.
- Strong evidence for Vietnamese model routing, Windows support, explicit model licensing, and offline model paths.
- Still unverified: Vietnamese accuracy on our scan samples, table reading order, CPU time, peak memory, total installed footprint, and a one-click Windows setup.
- Pin the exact package, model route, model files, hashes, and matching dictionary. Do not mix arbitrary model versions.

### 2.2 Tesseract 5.5.4 — baseline and fallback candidate

Sources:
- Engine: https://github.com/tesseract-ocr/tesseract
- Inspected main commit: 34f4e3ffc25847740a4b1d52d39d40e8013ace83 (2026-11-13)
- Latest release inspected: 5.5.4 (2026-10-28)
- Training data: https://github.com/tesseract-ocr/tessdata_best
- Inspected tessdata_best commit: e12c65a915945e4c28e237a9b52bc4a8f39a0cec (2024-03-09)
- Engine and tessdata_best license: Apache-2.0.
- Vietnamese model file: vie.traineddata, 12,435,550 bytes; blob SHA 28bc301dc848861eb6ba734b866152b2a04732fc.

Verified:
- The Tesseract README describes UTF-8 support, more than 100 languages, image input, and outputs including text, hOCR, searchable PDF, TSV, ALTO, and PAGE.
- The official tessdata_best repository contains a Vietnamese vie.traineddata model and states that its models use the LSTM OCR engine in Tesseract 4+.
- The Windows installation guide points to 32-bit and 64-bit Tesseract 4/5 installers provided by UB Mannheim.
- Language data is separate and must be placed in the tessdata directory; the executable may need to be added to PATH.
- Tesseract itself does not include a GUI.

Candidate role:
- RESEARCHED CANDIDATE / BASELINE COMPARATOR.
- Strong evidence for a dedicated Vietnamese model and local execution after installation.
- Still unverified: accuracy against RapidOCR, per-user Windows installation without administrator rights, model choice (fast versus best), and performance on skewed, low-resolution, multi-column, or table-heavy scans.
- OCR text output alone does not reconstruct a reliable table or full document layout.

### 2.3 PaddleOCR 3.7.0 — broader OCR/document AI candidate

Sources:
- Repository: https://github.com/PaddlePaddle/PaddleOCR
- Inspected main commit: dab3fe35379033fdcb2d0e9572fac0b36c9a9ebf (2026-09-16)
- Latest release inspected: v3.7.0 (2026-06-11)
- License: Apache-2.0.
- Key files: README.md, pyproject.toml, docs/version3.x/pipeline_usage/OCR.en.md, docs/FAQ.en.md.

Verified:
- The official language table lists Vietnamese (vi) for PP-OCRv5 and PP-OCRv6.
- README identifies Windows among supported operating systems and CPU/GPU among supported hardware.
- Current package metadata requires Python >=3.8 and lists classifiers through Python 3.13.
- The official FAQ documents local model directories and manually downloaded models for isolated/offline environments.
- PaddleOCR includes document parsing and structured output capabilities as well as text recognition.

Candidate role:
- RESEARCHED CANDIDATE / ALTERNATIVE DIRECT FRAMEWORK.
- Could be useful if direct control over OCR and document parsing is required.
- Still unverified: dependency footprint, Windows CPU installation, model storage/update behavior, and quality on the target documents.
- Audit model assets, dictionaries, and transitive dependencies individually before redistribution; repository-level license alone is not a complete bundled-asset audit.

### 2.4 Docling 2.150.0 — document-level parser with pluggable OCR

Sources:
- Repository: https://github.com/docling-project/docling
- Inspected main commit: b9bf356f9763095ca9d51e7452a054a7db20f237 (2026-11-13)
- Latest release inspected: v2.150.0 (2026-11-10)
- License: MIT.
- Key files: pyproject.toml and official installation/OCR documentation.

Verified:
- Package metadata describes a modular parser for PDF, DOCX, HTML, and more, with a unified document representation.
- Inspected metadata declares Python >=3.10 and Windows support.
- Its dependency declarations separate PDF, DOCX, XLSX, OCR, and other optional features.
- The official installation guide lists RapidOCR, EasyOCR, Tesseract CLI/binding, and other OCR engines.
- The standard Docling package includes RapidOCR by default. The guide says that when using Tesseract CLI alone, RapidOCR should be excluded and Tesseract explicitly selected.
- The Tesseract integration requires a system Tesseract installation and discoverable language data.

Candidate role:
- RESEARCHED CANDIDATE / PRIORITY TO COMPARE AS THE DOCUMENT-LEVEL INGESTION LAYER, not an OCR engine by itself.
- It may combine PDF/DOCX/XLSX extraction, document layout representation, and a selectable OCR backend.
- Still unverified: total installed footprint, model cache and offline behavior, Vietnamese recognition with each selected engine, CPU/memory requirements, and results compared with MarkItDown.

### 2.5 EasyOCR 1.7.2 — secondary candidate

Sources:
- Repository: https://github.com/JaidedAI/EasyOCR
- Inspected master commit: 2f77e2e8125d666af859a57d49014731ecbf40c6 (2026-11-13)
- Latest stable release inspected: v1.7.2 (2024-09-24)
- Source license: Apache-2.0.
- Key files: README.md, LICENSE, easyocr/config.py.

Verified:
- The source language configuration includes vi in its Latin recognition language list.
- README supports CPU-only mode with gpu=False.
- Model weights can be downloaded automatically or manually.
- Windows setup instructions require PyTorch and torchvision to be installed separately first.

Candidate role:
- RESEARCHED CANDIDATE / LOWER PRIORITY.
- Vietnamese and CPU mode are documented.
- Concerns: latest stable release inspected is from 2024, and separate PyTorch/torchvision setup increases installation complexity. Model-weight licensing and packaging need separate review.

## 3. Proposed test order — not an accuracy ranking

1. RapidOCR 3.10.0 with a pinned PP-OCRv6 multilingual route including vi, using ONNX Runtime.
2. Tesseract 5.5.4 with the vie model from tessdata_best as a baseline/fallback.
3. Docling 2.150.0 as a document-level comparison, using RapidOCR and Tesseract configurations.
4. PaddleOCR directly if Docling/RapidOCR does not provide sufficient control or document parsing.
5. EasyOCR only if the first candidates have a material quality gap.

No engine is approved.

## 4. Required OCR test corpus and acceptance measures

Use public or synthetic documents only. Never commit private or confidential user documents.

Test cases:
- Vietnamese scans with full diacritics and mixed English.
- Clean 300-dpi pages and lower-resolution scans.
- Skew, rotation, blur, compression artifacts, and faint print.
- Multi-column pages, tables, headers, footnotes, and page numbers.
- Numeric-heavy forms with dates, amounts, codes, and percentages.
- Multi-page PDFs containing both text-native and image-only pages.

Measure:
- Character error rate (CER) and word error rate (WER) against verified ground truth.
- Reading-order and table-cell extraction quality.
- Page throughput and time to first result.
- Peak memory and CPU use.
- Download size and installed footprint.
- Whether a second run works with networking disabled after models have been provisioned.
- Ease of per-user Windows installation and recovery.
- License and attribution completeness for code, model files, dictionaries, fonts, and transitive dependencies.

Do not report an OCR engine as best until the same corpus has been tested using pinned versions, model hashes, and reproducible settings.
