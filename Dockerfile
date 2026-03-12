FROM python:3.10-slim

WORKDIR /app

# system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# torch CPU (pip version = 작음)
RUN pip install --no-cache-dir \
    torch --index-url https://download.pytorch.org/whl/cpu

# whisper
RUN pip install --no-cache-dir openai-whisper gunicorn flask

ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1

ENV WHISPER_CACHE_DIR=/models
RUN mkdir -p /models

# preload
RUN python -c "import whisper; whisper.load_model('tiny', download_root='/models')"

COPY flask_app.py .

EXPOSE 5000

CMD ["gunicorn","--workers","1","--threads","1","--timeout","0","--bind","0.0.0.0:5000","flask_app:app"]