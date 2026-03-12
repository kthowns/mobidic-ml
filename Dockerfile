# -------------------------------------------------
# Base (초경량 conda 대체)
# -------------------------------------------------
FROM mambaorg/micromamba:1.5.8

WORKDIR /app

USER root

# -------------------------------------------------
# system dependencies
# -------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# conda environment
# -------------------------------------------------
RUN micromamba install -y -n base \
    python=3.10 \
    flask \
    pytorch cpuonly \
    intel-openmp \
    gunicorn \
    -c pytorch -c conda-forge \
    && micromamba clean --all --yes

# -------------------------------------------------
# CPU 안정화 (매우 중요)
# -------------------------------------------------
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1
ENV PYTHONUNBUFFERED=1

# -------------------------------------------------
# whisper cache
# -------------------------------------------------
ENV WHISPER_CACHE_DIR=/models
RUN mkdir -p /models

# whisper only (deps는 conda가 담당)
RUN pip install --no-cache-dir --no-deps openai-whisper

# 모델 build-time preload (cold start 제거)
RUN python -c "import whisper; whisper.load_model('tiny', download_root='/models')"

# -------------------------------------------------
# app copy
# -------------------------------------------------
COPY flask_app.py .

EXPOSE 5000

# -------------------------------------------------
# production run
# -------------------------------------------------
CMD ["gunicorn", \
     "--workers", "1", \
     "--threads", "1", \
     "--timeout", "0", \
     "--bind", "0.0.0.0:5000", \
     "flask_app:app"]