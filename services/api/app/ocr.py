"""Lazy, serialized PaddleOCR inference for uploaded images and rasterized PDFs."""

from functools import lru_cache
import os
from threading import Lock

from .config import get_settings

_inference_lock = Lock()


@lru_cache(maxsize=1)
def _engine():
    # Keep text-only PDF/DOCX extraction usable without loading the OCR models.
    os.environ.setdefault("PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK", "True")
    from paddleocr import PaddleOCR

    return PaddleOCR(
        device=get_settings().paddle_device,
        text_detection_model_name="PP-OCRv5_mobile_det",
        text_recognition_model_name="en_PP-OCRv5_mobile_rec",
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_textline_orientation=False,
    )


def extract_image(content: bytes) -> tuple[str, str, float]:
    import cv2
    import numpy as np

    image = cv2.imdecode(np.frombuffer(content, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError("The image could not be decoded. Upload a JPEG or PNG image.")
    # A cached Paddle predictor must not be used by concurrent processing threads.
    with _inference_lock:
        results = list(_engine().predict(image))
    lines: list[str] = []
    scores: list[float] = []
    for result in results:
        for text, score in zip(result["rec_texts"], result["rec_scores"], strict=True):
            if text.strip():
                lines.append(text.strip())
                scores.append(float(score))
    return "\n".join(lines), "paddleocr", sum(scores) / len(scores) if scores else 0.0
