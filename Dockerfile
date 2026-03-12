FROM continuumio/miniconda3

WORKDIR /app

# -----------------------------
# 1. system dependency
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# 2. python + torch (CPU only)
# -----------------------------
RUN conda install -y \
    python=3.10 \
    flask \
    pytorch torchvision torchaudio cpuonly -c pytorch \
    && conda clean -afy

# -----------------------------
# 3. CPU 안정화 (매우 중요)
# -----------------------------
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1

# -----------------------------
# 4. whisper model cache
# -----------------------------
ENV WHISPER_CACHE_DIR=/models
RUN mkdir -p /models

# whisper + production server
RUN pip install --no-cache-dir openai-whisper gunicorn \
    && python -c "import whisper; whisper.load_model('tiny', download_root='/models')"

# -----------------------------
# 5. app source
# -----------------------------
COPY flask_app.py .

EXPOSE 5000

# production server
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:5000", "flask_app:app"]