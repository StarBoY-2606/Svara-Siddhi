"""
Svara-Siddhi FastAPI Backend
Voice-Based Bio-Acoustic Wellness Tracker
"""

import os
import tempfile
import logging
from typing import List
from fastapi import FastAPI, File, Form, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
import uvicorn
from dotenv import load_dotenv

import ml_engine
import train_ravdess
import database

load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Svara-Siddhi API",
    description="Bio-Acoustic Wellness Tracker — Triguna Analysis Engine",
    version="1.0.0",
)

@app.on_event("startup")
def on_startup():
    """Initialise SQLite tables on server boot."""
    database.init_db()
    logger.info("Database ready.")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

VPI_QUESTIONS = [
    {"id": 1, "category": "Stress Response",
     "question": "How do you typically react under high pressure?",
     "options": {"A": "Remain calm and find a solution.", "B": "Become anxious, irritable, or hyperactive.", "C": "Shut down, avoid the problem, or feel overwhelmed."}},
    {"id": 2, "category": "Energy Levels",
     "question": "Describe your daily physical energy:",
     "options": {"A": "Steady, light, and consistent throughout the day.", "B": "Restless, intense bursts followed by sudden crashes.", "C": "Heavy, lethargic, difficult to get moving in the morning."}},
    {"id": 3, "category": "Sleep Patterns",
     "question": "How do you sleep?",
     "options": {"A": "Deep, wake up easily and feeling completely refreshed.", "B": "Interrupted, racing thoughts, very active dreams.", "C": "Very heavy, difficult to wake up, groggy for hours."}},
    {"id": 4, "category": "Dietary Preference",
     "question": "What foods do you naturally crave?",
     "options": {"A": "Fresh, light, warm, naturally sweet (fruits, grains).", "B": "Very spicy, salty, sour, or highly stimulating foods.", "C": "Heavy, processed, fried, or cold foods."}},
    {"id": 5, "category": "Emotional Tendency",
     "question": "What is your default emotional state when challenged?",
     "options": {"A": "Compassionate, forgiving, and understanding.", "B": "Competitive, aggressive, or easily frustrated.", "C": "Apathetic, resentful, or feeling like a victim."}},
    {"id": 6, "category": "Work Approach",
     "question": "How do you handle your daily tasks?",
     "options": {"A": "Focused, methodical, completing one thing at a time.", "B": "Multitasking, rushed, constantly moving to the next thing.", "C": "Procrastinating, slow, frequently leaving things unfinished."}},
    {"id": 7, "category": "Speech Pattern",
     "question": "How do others describe your way of speaking?",
     "options": {"A": "Clear, calm, truthful, and concise.", "B": "Fast, loud, persuasive, or argumentative.", "C": "Slow, repetitive, unclear, or complaining."}},
    {"id": 8, "category": "Learning Style",
     "question": "How do you react to new information or feedback?",
     "options": {"A": "Open-minded, reflective, and willing to learn.", "B": "Skeptical, immediately debating, or trying to prove them wrong.", "C": "Dismissive, ignoring it, or unable to process it."}},
]



class VpiRequest(BaseModel):
    answers: List[str]

    @field_validator("answers")
    @classmethod
    def validate_answers(cls, v: List[str]) -> List[str]:
        if len(v) != 8:
            raise ValueError("Exactly 8 answers required.")
        for a in v:
            if a not in ("A", "B", "C"):
                raise ValueError(f"Invalid answer '{a}'. Must be A, B, or C.")
        return v


class VpiResponse(BaseModel):
    baseline: str
    sattvic_count: int
    rajasic_count: int
    tamas_count: int
    questions: list



@app.get("/healthz")
def health():
    return {"status": "ok", "service": "Svara-Siddhi API"}


class TrainRequest(BaseModel):
    max_actors: int = 6


@app.get("/api/model/status")
def get_model_status():
    """Get the current model's details, parameters, metadata and active training status."""
    return train_ravdess.get_status()


@app.post("/api/model/train-ravdess")
def train_ravdess_model(body: TrainRequest = None):
    """Trigger background model training using the official RAVDESS dataset."""
    max_actors = 6
    if body and body.max_actors:
        max_actors = body.max_actors

    if max_actors < 1 or max_actors > 24:
        raise HTTPException(status_code=400, detail="max_actors must be between 1 and 24.")

    started = train_ravdess.start_training_in_background(max_actors=max_actors)
    if not started:
        raise HTTPException(status_code=400, detail="A training job is already in progress.")

    return {"status": "started", "message": f"RAVDESS training initiated in the background with max_actors={max_actors}."}


@app.get("/api/vpi/questions")
def get_vpi_questions():
    """Return all 8 VPI questions."""
    return {"questions": VPI_QUESTIONS}


@app.post("/api/vpi", response_model=VpiResponse)
def submit_vpi(body: VpiRequest):
    """
    Receive 8 VPI answers (A/B/C) and return the Guna baseline.
    A = Sattva, B = Rajas, C = Tamas
    """
    sattvic = body.answers.count("A")
    rajasic = body.answers.count("B")
    tamasic = body.answers.count("C")

    if sattvic >= rajasic and sattvic >= tamasic:
        baseline = "Sattvic"
    elif rajasic >= tamasic:
        baseline = "Rajasic"
    else:
        baseline = "Tamasic"

    logger.info(f"VPI submitted — S:{sattvic} R:{rajasic} T:{tamasic} → {baseline}")

    try:
        database.save_vpi_session(
            answers=body.answers,
            baseline=baseline,
            sattvic=sattvic,
            rajasic=rajasic,
            tamasic=tamasic,
        )
    except Exception as db_err:
        logger.warning(f"DB save failed (VPI): {db_err}")

    return VpiResponse(
        baseline=baseline,
        sattvic_count=sattvic,
        rajasic_count=rajasic,
        tamas_count=tamasic,
        questions=VPI_QUESTIONS,
    )


@app.post("/api/analyze-voice")
async def analyze_voice(
    audio_file: UploadFile = File(...),
    guna_baseline: str = Form(default="Sattvic"),
):
    """
    Accept a WAV audio upload, run bio-acoustic ML analysis,
    and return Guna state + prescription.
    """
    if guna_baseline not in ("Sattvic", "Rajasic", "Tamasic"):
        raise HTTPException(status_code=400, detail="Invalid guna_baseline.")

    allowed_types = {"audio/wav", "audio/wave", "audio/x-wav", "audio/mpeg", "audio/mp4", "application/octet-stream"}
    if audio_file.content_type and audio_file.content_type not in allowed_types:
        logger.warning(f"Received content-type: {audio_file.content_type}")

    suffix = ".wav"
    if audio_file.filename and audio_file.filename.endswith(".m4a"):
        suffix = ".m4a"

    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        content = await audio_file.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        logger.info(f"Analyzing voice — baseline: {guna_baseline}, file: {tmp_path}, size: {len(content)} bytes")
        result = ml_engine.analyze(wav_path=tmp_path, vpi_baseline=guna_baseline)
        logger.info(f"Analysis complete — predicted: {result['guna_state']}")

        try:
            scores = result.get("guna_scores", {})
            database.save_voice_session(
                vpi_baseline=guna_baseline,
                guna_state=result["guna_state"],
                sattvic_score=scores.get("Sattvic", 0.0),
                rajasic_score=scores.get("Rajasic", 0.0),
                tamasic_score=scores.get("Tamasic", 0.0),
                transcript=result.get("transcript"),
                prescription=str(result.get("prescription", "")),
                file_size_bytes=len(content),
            )
        except Exception as db_err:
            logger.warning(f"DB save failed (voice): {db_err}")

        return result
    except Exception as e:
        logger.error(f"Analysis failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Analysis error: {str(e)}")
    finally:
        os.unlink(tmp_path)



@app.get("/api/history/vpi")
def vpi_history(user_id: str = "default", limit: int = 20):
    """Return past VPI sessions from the database."""
    return {"sessions": database.get_vpi_history(user_id=user_id, limit=limit)}


@app.get("/api/history/voice")
def voice_history(user_id: str = "default", limit: int = 20):
    """Return past voice analysis sessions from the database."""
    return {"sessions": database.get_voice_history(user_id=user_id, limit=limit)}


@app.get("/api/stats")
def app_stats():
    """Return aggregate database statistics."""
    return database.get_all_stats()



if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
