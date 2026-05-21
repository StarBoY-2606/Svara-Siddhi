# Svara-Siddhi — Setup Guide
## Flutter + FastAPI + librosa + scikit-learn + OpenAI Whisper

## Folder Structure

svara_siddhi/
├── backend/
│   ├── main.py          ← FastAPI server (all 3 endpoints)
│   ├── ml_engine.py     ← librosa + Random Forest + Whisper
│   └── requirements.txt
└── flutter/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart                  ← App entry + bottom tab shell
        ├── constants/
        │   ├── app_theme.dart         ← Colors, ThemeData
        │   └── app_config.dart        ← API base URL (edit this!)
        ├── models/
        │   └── analysis_result.dart   ← JSON models
        ├── services/
        │   └── api_service.dart       ← HTTP client
        └── screens/
            ├── home_screen.dart       ← Welcome + baseline display
            ├── vpi_screen.dart        ← 8-question VPI questionnaire
            ├── record_screen.dart     ← Audio recording + upload
            ├── results_screen.dart    ← Guna state + prescription
            ├── practices_screen.dart  ← Yogic practices library
            └── history_screen.dart    ← Session history

## 1. Backend Setup (FastAPI + Python)

### Prerequisites
- Python 3.10+
- pip

### Install & Run

```bash
cd svara_siddhi/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate        # macOS/Linux
# venv\Scripts\activate         # Windows

# Install dependencies
pip install -r requirements.txt

# (Optional) Set OpenAI API key for Whisper transcription
$env:OPENAI_API_KEY="sk-your-actual-api-key-here"

# Start the server
python main.py or 
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
# Server runs at http://localhost:8000
# API docs at  http://localhost:8000/docs
```

The Random Forest model trains automatically on first startup (~2 seconds) using synthetic bio-acoustic data and is saved to disk for subsequent runs.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /healthz | Health check |
| GET | /api/vpi/questions | All 8 VPI questions |
| POST | /api/vpi | Submit answers → Guna baseline |
| POST | /api/analyze-voice | Upload audio → analysis result |

---

## 2. Flutter App Setup

### Prerequisites
- Flutter SDK 3.19+  (`flutter --version`)
- Android Studio / Xcode

### Configure API URL

Edit `lib/constants/app_config.dart`:

```dart
// Android emulator → FastAPI on your machine
static const String apiBaseUrl = 'http://10.0.2.2:8000';

// iOS simulator
static const String apiBaseUrl = 'http://localhost:8000';

// Physical device (replace with your machine's local IP)
static const String apiBaseUrl = 'http://192.168.1.x:8000';
```

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

For HTTP (non-HTTPS) on Android, add inside `<application>`:
```xml
android:usesCleartextTraffic="true"
```

### iOS Permissions

Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Svara-Siddhi analyzes your voice to map Triguna indices.</string>
```

### Install & Run

```bash
cd svara_siddhi/flutter

flutter pub get
flutter run
```

---

## 3. Architecture Overview

```
Flutter App
    │
    ├─ VPI Screen → POST /api/vpi
    │       └─ FastAPI scores A/B/C answers → returns baseline Guna
    │
    └─ Record Screen → POST /api/analyze-voice (WAV file upload)
            └─ ml_engine.py:
                ├─ librosa.load() → raw waveform
                ├─ mfcc() → 13 MFCCs (Prana texture)
                ├─ pyin() → Pitch F0 (Hz)
                ├─ rms() → Energy (Prana strength)
                ├─ OpenAI Whisper → transcript
                ├─ Rule-based sentiment → Guna sentiment tag
                └─ RandomForestClassifier.predict_proba()
                    + VPI baseline blend (60/20/20)
                    → Guna state + prescription JSON
```

---

## 4. Module Mapping (per spec)

| Module | File(s) |
|--------|---------|
| Module 1 — VPI 8-Question Logic | `vpi_screen.dart`, `main.py (/api/vpi)` |
| Module 2 — Bio-Acoustic ML Engine | `ml_engine.py` |
| Module 3 — Core FastAPI | `main.py` |
| Module 4 — Flutter Frontend | All `screens/*.dart` |
| Module 5 — Correction Engine UI | `results_screen.dart` (Tamasic/Rajasic/Sattvic theming) |
