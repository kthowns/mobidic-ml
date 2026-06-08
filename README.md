# Mobidic-ML (Whisper STT Server)

OpenAI의 **Whisper** 모델을 활용하여 음성 파일을 텍스트로 변환(Speech-to-Text)하는 경량 Flask 서버입니다. Docker 기반으로 구성되어 있으며, CPU 환경에서 효율적으로 동작하도록 최적화되어 있습니다.

## 주요 기능

- **음성 인식 (STT):** `/transcribe` 엔드포인트를 통해 음성 파일을 텍스트로 변환합니다.
- **Whisper `base.en` 모델 사용:** 영어 인식에 최적화된 경량 모델을 사용합니다.
- **Docker 컨테이너화:** 어디서든 동일한 환경으로 실행 가능합니다.
- **Health Check:** `/health` 엔드포인트를 통해 서버 상태를 확인할 수 있습니다.

## 기술 스택

- **Backend:** Python 3.10, Flask, Gunicorn
- **ML Engine:** OpenAI Whisper
- **Infrastructure:** Docker, Docker Compose
- **System Deps:** FFmpeg (오디오 처리용)

## 프로젝트 구조

```text
.
├── flask_app.py           # Flask 애플리케이션 메인 로직
├── Dockerfile             # Docker 이미지 빌드 설정
├── docker-compose.yml     # 서비스 배포 설정
├── .github/workflows/     # CI/CD (GitHub Actions) 설정
└── 테스트용 음성 파일/      # 테스트를 위한 오디오 샘플들
```

## 시작하기

### 요구 사항

- Docker & Docker Compose
- 전용 네트워크 설정 (docker-compose 사용 시 필요)
  ```bash
  docker network create mobidic-net
  ```

### 직접 실행 (Docker)

1. **이미지 빌드**
   ```bash
   docker build -t mobidic-whisper .
   ```

2. **컨테이너 실행**
   ```bash
   docker run -p 5000:5000 mobidic-whisper
   ```

### Docker Compose로 실행

```bash
docker-compose up -d
```

## API 명세

### 1. 음성 텍스트 변환 (Transcribe)

음성 파일을 전송하여 텍스트 결과를 받습니다.

- **URL:** `/transcribe`
- **Method:** `POST`
- **Content-Type:** `multipart/form-data`
- **Request Body:**
  - `file`: (Binary) 변환할 음성 파일 (mp3, m4a, wav 등)
- **Response:**
  - `200 OK`: `{"result": "Recognized text here..."}`
  - `400 Bad Request`: 파일이 없거나 잘못된 요청일 경우
  - `500 Internal Server Error`: 처리 중 에러 발생 시

**cURL 예시:**
```bash
curl -X POST -F "file=@./테스트용 음성 파일/apple.mp3" http://localhost:5000/transcribe
```

### 2. 헬스 체크 (Health Check)

서버 생존 여부를 확인합니다.

- **URL:** `/health`
- **Method:** `GET`
- **Response:** `{"status": "ok"}`

## 최적화 정보

- **CPU 전용:** PyTorch의 CPU 전용 버전을 사용하여 이미지 용량을 줄였습니다.
- **병렬 처리 제한:** CPU 부하를 제어하기 위해 `OMP_NUM_THREADS=1`, `MKL_NUM_THREADS=1`로 설정되어 있습니다.
- **Preload:** Docker 빌드 단계에서 모델을 미리 다운로드하여 실행 시 속도를 높였습니다.
