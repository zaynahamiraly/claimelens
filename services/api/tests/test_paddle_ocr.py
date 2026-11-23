import io
import numpy as np
import pytest
from PIL import Image
from app import ocr, processing


def png():
    output = io.BytesIO()
    Image.new('RGB', (80, 80), 'white').save(output, 'PNG')
    return output.getvalue()


def test_paddle_lines_and_confidence(monkeypatch):
    class Engine:
        def predict(self, image):
            assert image.shape == (80, 80, 3)
            yield {'rec_texts': ['Invoice', ' ', 'Total MUR 1250.00'], 'rec_scores': np.array([.9, .1, .7])}
    monkeypatch.setattr(ocr, '_engine', lambda: Engine())
    text, method, confidence = ocr.extract_image(png())
    assert text == 'Invoice\nTotal MUR 1250.00'
    assert method == 'paddleocr'
    assert confidence == pytest.approx(.8)


def test_low_confidence_is_not_artificially_increased(monkeypatch):
    class Engine:
        def predict(self, image):
            yield {'rec_texts': ['uncertain'], 'rec_scores': [.12]}
    monkeypatch.setattr(ocr, '_engine', lambda: Engine())
    assert ocr.extract_image(png())[2] == .12


def test_invalid_image_does_not_initialize_models(monkeypatch):
    def unexpected():
        raise AssertionError('Model must not load for invalid bytes')
    monkeypatch.setattr(ocr, '_engine', unexpected)
    with pytest.raises(ValueError, match='could not be decoded'):
        ocr.extract_image(b'not an image')


def test_scanned_pdf_routes_to_paddle(monkeypatch):
    import pymupdf
    calls = []
    def recognize(content):
        calls.append(content)
        return 'Total MUR 1250.00', 'paddleocr', .9
    monkeypatch.setattr(ocr, 'extract_image', recognize)
    with pymupdf.open() as pdf:
        pdf.new_page().insert_image(pymupdf.Rect(0, 0, 80, 80), stream=png())
        result = processing.extract_document_text(pdf.tobytes(), 'application/pdf')
    assert calls and result == ('Total MUR 1250.00', 'paddleocr', .9)


def test_digital_pdf_does_not_load_ocr(monkeypatch):
    import pymupdf
    monkeypatch.setattr(ocr, '_engine', lambda: pytest.fail('Digital PDF should use embedded text'))
    with pymupdf.open() as pdf:
        pdf.new_page().insert_text((50, 50), 'Invoice for medical treatment. Patient name: Test Person. Total MUR 1250.00')
        text, method, _ = processing.extract_document_text(pdf.tobytes(), 'application/pdf')
    assert method == 'pdf_text' and '1250' in text
