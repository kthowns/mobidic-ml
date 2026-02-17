from flask import Flask, request, jsonify
import uuid
import whisper
import os
from concurrent.futures import ThreadPoolExecutor

app = Flask(__name__)
model = whisper.load_model("tiny.en")
executor = ThreadPoolExecutor(max_workers=4)  # 쓰레드 4개

def transcribe_audio(audio_path):
    result = model.transcribe(audio_path)
    return result['text']

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    audio_path = os.path.join('uploads', f"{uuid.uuid4().hex}.wav")
    os.makedirs('uploads', exist_ok=True)
    file.save(audio_path)

    future = executor.submit(transcribe_audio, audio_path)

    try:
        text = future.result()  # 여기서 기다리긴 함 (비동기 submit했지만 최종 결과 대기)
        os.remove(audio_path)
        return jsonify({"result": text}), 200
    except Exception as e:
        os.remove(audio_path)
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
