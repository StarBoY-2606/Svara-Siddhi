"""
Svara-Siddhi ML Engine
Bio-Acoustic & Contextual Analysis for Triguna Prediction
"""

import os
import numpy as np
import librosa
from typing import Optional, Any
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.neural_network import MLPClassifier
import pickle
import logging

logger = logging.getLogger(__name__)


PRESCRIPTIONS = {
    "Sattvic": {
        "prescription": (
            "Current State: Sattvic (Balanced). Prescription: Maintain your state "
            "with gentle Anulom Vilom (Alternate Nostril Breathing) or silent Dhyana."
        ),
        "technique": "Anulom Vilom & Dhyana",
    },
    "Rajasic": {
        "prescription": (
            "Current State: Rajasic (High Agitation). Prescription: Perform "
            'low-frequency, elongated "OM" chanting or Shitali Pranayama.'
        ),
        "technique": "OM Chanting & Shitali Pranayama",
    },
    "Tamasic": {
        "prescription": (
            "Current State: Tamasic (Low Prana). Prescription: Perform "
            "high-frequency, rhythmic Kapalbhati Pranayama or chant Bija Mantras (Ram, Hum)."
        ),
        "technique": "Kapalbhati & Bija Mantras",
    },
}

GUNA_LABELS = {0: "Tamasic", 1: "Rajasic", 2: "Sattvic"}
GUNA_INDEX = {"Tamasic": 0, "Rajasic": 1, "Sattvic": 2}



def _clamp(val: float, min_val: float = 0.0, max_val: float = 1.0) -> float:
    return max(min_val, min(val, max_val))


def _calculate_doshas(pitch: float, energy: float, clarity: float, centroid: float) -> tuple[int, int, int]:
    """
    Bio-acoustic rule engine for Vata, Pitta, and Kapha distribution.
    Matches natural Ayurvedic voice attributes:
    - Vata: high/variable pitch, lower volume, breathy/airy.
    - Pitta: moderate pitch, high volume, sharp/resonant.
    - Kapha: low/stable pitch, warm volume, deep/clear.
    """
    vata = 0.32 * _clamp((pitch - 80.0) / 140.0) + 0.34 * (1.0 - clarity) + 0.18 * centroid + 0.16 * (1.0 - energy)
    pitta = 0.28 * _clamp((pitch - 90.0) / 130.0) + 0.34 * energy + 0.22 * clarity + 0.16 * centroid
    kapha = 0.44 * (1.0 - _clamp((pitch - 80.0) / 140.0)) + 0.34 * (1.0 - energy) + 0.12 * (1.0 - centroid) + 0.10 * (1.0 - clarity)

    total = vata + pitta + kapha
    if total <= 0:
        total = 1.0

    vata_pct = round((vata / total) * 100)
    pitta_pct = round((pitta / total) * 100)
    kapha_pct = 100 - vata_pct - pitta_pct
    return vata_pct, pitta_pct, kapha_pct


def compute_dosha_scores(features: dict) -> tuple[int, int, int]:
    """Calculate Vata, Pitta, Kapha distribution from extracted features."""
    pitch = features.get("pitch_hz", 145.0)
    energy_raw = features.get("rms_energy", 1.8)
    energy = _clamp(energy_raw / 4.0)
    
    zcr = features.get("zcr", 7.0)
    clarity = _clamp(max(0.0, 100.0 - zcr * 10.0) / 100.0)
    
    centroid_raw = features.get("spectral_centroid", 16.0)
    centroid = _clamp(centroid_raw / 30.0)
    
    return _calculate_doshas(pitch, energy, clarity, centroid)



def _generate_synthetic_data(n_samples: int = 1800):
    """
    Generate synthetic training data representing high-precision acoustic signatures.
    Features: 272 features (MFCCs, Deltas, Pitch, Mel Spectrogram, etc.)
    Labels: 0=Tamasic, 1=Rajasic, 2=Sattvic
    """
    np.random.seed(42)
    X, y = [], []

    for guna_idx in range(3):
        for _ in range(n_samples // 3):
            if guna_idx == 0:  # Tamasic
                pitch = np.random.normal(115, 25)
                energy = np.random.normal(0.8, 0.3)
                centroid = np.random.normal(10.0, 2.0)
                zcr = np.random.normal(4.0, 1.5)
                rolloff = np.random.normal(10.0, 2.0)
                rest = np.random.normal(0.0, 1.0, 272 - 5)
            elif guna_idx == 1:  # Rajasic
                pitch = np.random.normal(175, 35)
                energy = np.random.normal(3.2, 0.8)
                centroid = np.random.normal(22.0, 4.0)
                zcr = np.random.normal(11.0, 3.0)
                rolloff = np.random.normal(25.0, 5.0)
                rest = np.random.normal(1.0, 2.0, 272 - 5)
            else:  # Sattvic
                pitch = np.random.normal(145, 35)
                energy = np.random.normal(1.8, 0.5)
                centroid = np.random.normal(16.0, 3.0)
                zcr = np.random.normal(7.0, 2.0)
                rolloff = np.random.normal(17.0, 3.0)
                rest = np.random.normal(0.5, 0.5, 272 - 5)

            features = np.concatenate([rest[:120], [pitch, energy, centroid, zcr, rolloff], rest[120:]])
            X.append(features)
            y.append(guna_idx)

    return np.array(X), np.array(y)



_model: Optional[Any] = None
_scaler: Optional[StandardScaler] = None


def _load_or_train_model():
    global _model, _scaler
    model_path = "svara_model.pkl"
    scaler_path = "svara_scaler.pkl"

    if os.path.exists(model_path) and os.path.exists(scaler_path):
        with open(model_path, "rb") as f:
            _model = pickle.load(f)
        with open(scaler_path, "rb") as f:
            _scaler = pickle.load(f)
        logger.info("Loaded existing Svara-Siddhi model from disk.")
        return

    logger.info("Training new Machine Learning model (Random Forest) on synthetic data...")
    X, y = _generate_synthetic_data(n_samples=1800)
    
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import accuracy_score
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    _scaler = StandardScaler()
    X_train_scaled = _scaler.fit_transform(X_train)
    X_test_scaled = _scaler.transform(X_test)
    
    _model = RandomForestClassifier(
        n_estimators=150,
        max_depth=15,
        random_state=42,
        class_weight="balanced"
    )
    _model.fit(X_train_scaled, y_train)
    
    y_pred = _model.predict(X_test_scaled)
    acc = accuracy_score(y_test, y_pred)
    logger.info(f"Model trained successfully. Validation Accuracy: {acc * 100:.2f}%")

    X_full_scaled = _scaler.fit_transform(X)
    _model.fit(X_full_scaled, y)

    with open(model_path, "wb") as f:
        pickle.dump(_model, f)
    with open(scaler_path, "wb") as f:
        pickle.dump(_scaler, f)
    logger.info("Model trained and saved.")



def extract_features(wav_path: str) -> dict:
    """
    Extract high-precision bio-acoustic features from a WAV file using librosa.
    Returns:
        dict with keys: mfccs, mfccs_delta, mfccs_delta2, pitch_hz, rms_energy, 
        spectral_centroid, zcr, rolloff, chroma, mel, contrast
    """
    y, sr = librosa.load(wav_path, sr=22050, mono=True, duration=30.0)

    mfcc_matrix = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40)
    mfccs = np.mean(mfcc_matrix, axis=1).tolist()
    
    delta_mfcc = librosa.feature.delta(mfcc_matrix)
    delta2_mfcc = librosa.feature.delta(mfcc_matrix, order=2)
    mfccs_delta = np.mean(delta_mfcc, axis=1).tolist()
    mfccs_delta2 = np.mean(delta2_mfcc, axis=1).tolist()

    try:
        f0 = librosa.yin(y=y, sr=sr, fmin=librosa.note_to_hz("C2"), fmax=librosa.note_to_hz("C7"))
        f0_clean = f0[~np.isnan(f0)]
        pitch_hz = float(np.nanmean(f0_clean)) if len(f0_clean) > 0 else 145.0
    except Exception:
        pitch_hz = 145.0  # Fallback to Sattvic mean

    rms = librosa.feature.rms(y=y)
    rms_energy = float(np.mean(rms) * 100)

    spec_centroid = librosa.feature.spectral_centroid(y=y, sr=sr)
    centroid_mean = float(np.mean(spec_centroid) / 100)

    zcr = librosa.feature.zero_crossing_rate(y=y)
    zcr_mean = float(np.mean(zcr) * 100)

    try:
        rolloff_matrix = librosa.feature.spectral_rolloff(y=y, sr=sr)
        rolloff_mean = float(np.mean(rolloff_matrix) / 100)
    except Exception:
        rolloff_mean = 17.0  # Fallback Sattvic rolloff mean

    try:
        chroma_matrix = librosa.feature.chroma_stft(y=y, sr=sr, n_chroma=12)
        chroma = np.mean(chroma_matrix, axis=1).tolist()
    except Exception:
        chroma = [0.5] * 12  # Fallback Sattvic chroma mean

    mel_matrix = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=128)
    mel = np.mean(mel_matrix, axis=1).tolist()
    
    try:
        contrast_matrix = librosa.feature.spectral_contrast(y=y, sr=sr)
        contrast = np.mean(contrast_matrix, axis=1).tolist()
    except Exception:
        contrast = [0.0] * 7

    return {
        "mfccs": mfccs,
        "mfccs_delta": mfccs_delta,
        "mfccs_delta2": mfccs_delta2,
        "pitch_hz": pitch_hz,
        "rms_energy": rms_energy,
        "spectral_centroid": centroid_mean,
        "zcr": zcr_mean,
        "rolloff": rolloff_mean,
        "chroma": chroma,
        "mel": mel,
        "contrast": contrast,
    }



SATTVIC_WORDS = {"peace", "calm", "clear", "happ", "grate", "love", "balanc", "good", "well", "fine", "light", "gentle", "content"}
RAJASIC_WORDS = {"angr", "frustrat", "rush", "busy", "stress", "anxi", "fast", "compet", "irrit", "pressur", "urgent", "intens"}
TAMASIC_WORDS = {"tire", "heav", "slow", "lazy", "dull", "fogg", "stuck", "letharg", "confus", "overwhelm", "withdraw", "numb"}


def analyze_sentiment(transcript: str) -> str:
    """Rule-based sentiment analysis mapping to Guna categories with stem matching."""
    if not transcript:
        return "neutral"
    clean_text = transcript.lower()
    s = sum(1 for stem in SATTVIC_WORDS if stem in clean_text)
    r = sum(1 for stem in RAJASIC_WORDS if stem in clean_text)
    t = sum(1 for stem in TAMASIC_WORDS if stem in clean_text)
    if s == r == t == 0:
        return "neutral"
    mx = max(s, r, t)
    if mx == s:
        return "Sattvic"
    if mx == r:
        return "Rajasic"
    return "Tamasic"


def transcribe_audio(wav_path: str) -> str:
    """Transcribe audio using OpenAI Whisper API. Returns empty string on failure."""
    api_key = os.getenv("OPENAI_API_KEY", "")
    if not api_key:
        logger.warning("OPENAI_API_KEY not set — skipping transcription.")
        return ""
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key)
        with open(wav_path, "rb") as f:
            result = client.audio.transcriptions.create(
                model="whisper-1",
                file=f,
                response_format="text",
            )
        return str(result)
    except Exception as e:
        logger.warning(f"Whisper transcription failed: {e}")
        return ""



def predict_guna(features: dict, sentiment: str, vpi_baseline: str) -> tuple[str, list[float]]:
    """
    Fuse acoustic features + sentiment + VPI baseline to predict real-time Guna.

    Returns: (guna_label, [tamas_prob, rajas_prob, sattva_prob])
    """
    if _model is None or _scaler is None:
        _load_or_train_model()

    pitch_val = float(features.get("pitch_hz", 0.0))
    if pitch_val <= 0.0:
        pitch_val = 145.0

    feature_vector = np.array(
        features["mfccs"]
        + features["mfccs_delta"]
        + features["mfccs_delta2"]
        + [
            pitch_val,
            features["rms_energy"],
            features["spectral_centroid"],
            features["zcr"],
            features["rolloff"],
        ]
        + features["chroma"]
        + features["mel"]
        + features["contrast"]
    ).reshape(1, -1)

    feature_vector_scaled = _scaler.transform(feature_vector)
    probs = _model.predict_proba(feature_vector_scaled)[0].tolist()

    vpi_boost = [0.0, 0.0, 0.0]
    vpi_idx = GUNA_INDEX.get(vpi_baseline, 2)
    vpi_boost[vpi_idx] = 1.0

    sentiment_boost = [0.0, 0.0, 0.0]
    if sentiment != "neutral":
        sentiment_boost[GUNA_INDEX[sentiment]] = 1.0
    else:
        sentiment_boost = [1 / 3, 1 / 3, 1 / 3]

    fused = [
        0.40 * probs[i] + 0.40 * vpi_boost[i] + 0.20 * sentiment_boost[i]
        for i in range(3)
    ]
    predicted_idx = int(np.argmax(fused))
    return GUNA_LABELS[predicted_idx], fused



def analyze(wav_path: str, vpi_baseline: str) -> dict:
    """
    Full analysis pipeline: feature extraction → transcription → prediction.

    Args:
        wav_path: Path to the recorded WAV file.
        vpi_baseline: User's VPI baseline Guna ('Sattvic', 'Rajasic', 'Tamasic').

    Returns:
        dict with all bio-markers, transcript, prediction, and prescription.
    """
    if _model is None:
        _load_or_train_model()

    features = extract_features(wav_path)
    transcript = transcribe_audio(wav_path)
    sentiment = analyze_sentiment(transcript)
    guna_state, probs = predict_guna(features, sentiment, vpi_baseline)

    total = sum(probs) or 1.0
    sattvic_pct = round((probs[2] / total) * 100)
    rajasic_pct = round((probs[1] / total) * 100)
    tamas_pct = 100 - sattvic_pct - rajasic_pct
    vata_pct, pitta_pct, kapha_pct = compute_dosha_scores(features)

    prescription_data = PRESCRIPTIONS[guna_state]

    return {
        "guna_state": guna_state,
        "sattvic_score": sattvic_pct,
        "rajasic_score": rajasic_pct,
        "tamas_score": tamas_pct,
        "vata_score": vata_pct,
        "pitta_score": pitta_pct,
        "kapha_score": kapha_pct,
        "pitch": round(features["pitch_hz"]),
        "energy": round(features["rms_energy"]),
        "clarity": round(max(0, 100 - features["zcr"] * 10)),
        "mfccs": [round(m, 3) for m in features["mfccs"]],
        "transcript": transcript,
        "sentiment": sentiment,
        "prescription": prescription_data["prescription"],
        "technique": prescription_data["technique"],
    }


_load_or_train_model()
