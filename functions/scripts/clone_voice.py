#!/usr/bin/env python3
import argparse
import contextlib
import os
import re
import subprocess
import tempfile
import wave


def split_text(text: str, max_chars: int = 220):
    sentences = [
        part.strip()
        for part in re.split(r"(?<=[.!?…])\s+", text.strip())
        if part.strip()
    ]
    if not sentences:
        return []

    chunks = []
    current = ""
    for sentence in sentences:
        candidate = sentence if not current else f"{current} {sentence}"
        if len(candidate) <= max_chars:
            current = candidate
            continue
        if current:
            chunks.append(current)
        current = sentence
    if current:
        chunks.append(current)
    return chunks


def concat_wavs(input_paths, output_path):
    if not input_paths:
        raise SystemExit("Ses parcalari olusturulamadi.")

    with contextlib.closing(wave.open(input_paths[0], "rb")) as first:
        params = first.getparams()
        with contextlib.closing(wave.open(output_path, "wb")) as out:
            out.setparams(params)
            for wav_path in input_paths:
                with contextlib.closing(wave.open(wav_path, "rb")) as wav_file:
                    out.writeframes(wav_file.readframes(wav_file.getnframes()))


def convert_wav_to_mp3(input_path, output_path):
    process = subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i",
            input_path,
            "-codec:a",
            "libmp3lame",
            "-qscale:a",
            "4",
            output_path,
        ],
        capture_output=True,
        text=True,
    )
    if process.returncode != 0:
        raise SystemExit(
            f"FFmpeg donusumu basarisiz oldu: {process.stderr.strip()}"
        )


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

    chunks = split_text(text)
    if not chunks:
        raise SystemExit("Islenecek metin parcasi bulunamadi.")

    with tempfile.TemporaryDirectory(prefix="masalevi-xtts-") as temp_dir:
        tts = TTS(args.model, progress_bar=False).to("cpu")
        chunk_paths = []

        for index, chunk in enumerate(chunks):
            chunk_path = os.path.join(temp_dir, f"chunk_{index:03d}.wav")
            tts.tts_to_file(
                text=chunk,
                speaker_wav=args.speaker,
                language=args.language,
                file_path=chunk_path,
            )
            chunk_paths.append(chunk_path)

        merged_wav_path = os.path.join(temp_dir, "merged.wav")
        concat_wavs(chunk_paths, merged_wav_path)
        convert_wav_to_mp3(merged_wav_path, args.output)


if __name__ == "__main__":
    main()
