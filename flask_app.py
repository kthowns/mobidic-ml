from flask import Flask, request, jsonify
import uuid
import whisper
import os

app = Flask(__name__)

# -----------------------------
# model load (container start 1회)
# -----------------------------
MODEL_NAME = "tiny"
MODEL_PATH = "/models"

model = whisper.load_model(
    MODEL_NAME,
    download_root=MODEL_PATH
)

UPLOAD_DIR = "/tmp"  # tmpfs 사용 (디스크 누수 방지)


def transcribe_audio(audio_path):
    result = model.transcribe(
        audio_path,
        fp16=False # CPU 환경 필수
    )
    return result["text"]


@app.route("/transcribe", methods=["POST"])
def transcribe():

    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    audio_path = os.path.join(
        UPLOAD_DIR,
        f"{uuid.uuid4().hex}.wav"
    )

    try:
        file.save(audio_path)

        # 단일 CPU 환경 → 직렬 처리 최적
        text = transcribe_audio(audio_path)

        return jsonify({"result": text}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if os.path.exists(audio_path):
            os.remove(audio_path)


@app.route("/health", methods=["GET"])
def health():
    return {"status": "ok"}, 200