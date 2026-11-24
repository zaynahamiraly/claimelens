"""Start the mobile API after PaddleOCR models are ready."""

import argparse
import logging

import uvicorn

from .ocr import _engine


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    logging.info("Loading PaddleOCR models before accepting uploads...")
    _engine()
    logging.info("PaddleOCR models are ready.")
    uvicorn.run("app.main:app", host=args.host, port=args.port)


if __name__ == "__main__":
    main()
