FROM continuumio/anaconda3

WORKDIR /app

COPY ./flask_app.py /app

RUN conda install -y flask \
 && conda install -y -c pytorch pytorch torchvision torchaudio cpuonly \
 && conda install -y -c conda-forge ffmpeg \
 && pip install openai-whisper

CMD ["python", "flask_app.py"]
