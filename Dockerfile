FROM continuumio/miniconda3

WORKDIR /app

# system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# conda (binary ecosystem 완성)
RUN conda install -y \
    python=3.10 \
    flask \
    pytorch torchvision torchaudio cpuonly \
    intel-openmp \
    -c pytorch -c conda-forge \
    && conda clean -afy

# CPU 안정화
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1
ENV PYTHONUNBUFFERED=1

# whisper cache
ENV WHISPER_CACHE_DIR=/models
RUN mkdir -p /models

# pip (dependency 설치 금지)
RUN pip install --no-cache-dir --no-deps openai-whisper gunicorn \
    && python -c "import whisper; whisper.load_model('tiny', download_root='/models')"

COPY flask_app.py .

EXPOSE 5000

CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:5000", "flask_app:app"]