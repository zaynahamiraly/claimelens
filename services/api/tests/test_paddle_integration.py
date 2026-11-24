"""Opt-in real model tests: RUN_PADDLE_OCR_TESTS=1 python -m pytest -q.

Uses generated documents only; downloads official model weights on first run.
"""

import os
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_PADDLE_OCR_TESTS") != "1", reason="Real Paddle model test is opt-in"
)


def test_real_paddle_extracts_image_and_scanned_pdf():
    import pymupdf
    from app.processing import extract_document_text
    from app.extraction import TextDocument, extract_fields

    with pymupdf.open() as source:
        page = source.new_page(width=600, height=400)
        page.insert_text((40, 70), "MEDICAL INVOICE", fontsize=28)
        page.insert_text((40, 120), "Patient name: Test Person", fontsize=20)
        page.insert_text((40, 170), "Total: MUR 1250.00", fontsize=24)
        image = page.get_pixmap(matrix=pymupdf.Matrix(2, 2)).tobytes("png")
    with pymupdf.open() as scanned:
        scanned.new_page(width=600, height=400).insert_image(
            pymupdf.Rect(0, 0, 600, 400), stream=image
        )
        pdf = scanned.tobytes()
    for content, mime in [(image, "image/png"), (pdf, "application/pdf")]:
        text, method, confidence = extract_document_text(content, mime)
        assert method == "paddleocr"
        assert "1250" in text
        assert 0 < confidence <= 1
        _, amount, currency, _ = extract_fields(
            TextDocument("synthetic-test", text, method, confidence)
        )
        assert amount == "1250.00"
        assert currency == "MUR"
