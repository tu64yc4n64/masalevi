#!/usr/bin/env python3
import argparse


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--speaker", required=True)
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--language", default="tr")
    parser.add_argument(
        "--model",
        default="tts_models/multilingual/multi-dataset/xtts_v2",
    )
    args = parser.parse_args()

    try:
        from TTS.api import TTS
    except Exception as exc:
        raise SystemExit(
            "Coqui TTS kurulu degil. Kurulum icin: pip install TTS"
        ) from exc

    with open(args.text_file, "r", encoding="utf-8") as text_file:
        text = text_file.read().strip()

    if not text:
        raise SystemExit("Bos metin ile ses uretilemez.")

    tts = TTS(args.model, progress_bar=False).to("cpu")
    tts.tts_to_file(
        text=text,
        speaker_wav=args.speaker,
        language=args.language,
        file_path=args.output,
    )


if __name__ == "__main__":
    main()
