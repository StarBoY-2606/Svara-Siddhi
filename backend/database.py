"""
Svara-Siddhi — SQLite Database Layer
Persists VPI sessions and voice analysis results across restarts.
"""

import sqlite3
import os
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)

DB_PATH = os.path.join(os.path.dirname(__file__), "svara.db")


def get_connection() -> sqlite3.Connection:
    """Return a SQLite connection with row_factory for dict-like access."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Create all tables on startup if they do not already exist."""
    with get_connection() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS vpi_sessions (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id     TEXT    NOT NULL DEFAULT 'default',
                answers     TEXT    NOT NULL,          -- comma-separated: A,B,C,...
                baseline    TEXT    NOT NULL,          -- Sattvic / Rajasic / Tamasic
                sattvic     INTEGER NOT NULL,
                rajasic     INTEGER NOT NULL,
                tamasic     INTEGER NOT NULL,
                created_at  TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS voice_sessions (
                id              INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id         TEXT    NOT NULL DEFAULT 'default',
                vpi_baseline    TEXT    NOT NULL,
                guna_state      TEXT    NOT NULL,
                sattvic_score   REAL    NOT NULL,
                rajasic_score   REAL    NOT NULL,
                tamasic_score   REAL    NOT NULL,
                transcript      TEXT,
                prescription    TEXT,
                file_size_bytes INTEGER,
                created_at      TEXT    NOT NULL
            );
        """)
    logger.info("SQLite database initialised at %s", DB_PATH)



def save_vpi_session(
    answers: List[str],
    baseline: str,
    sattvic: int,
    rajasic: int,
    tamasic: int,
    user_id: str = "default",
) -> int:
    """Insert a VPI session and return the new row id."""
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO vpi_sessions
               (user_id, answers, baseline, sattvic, rajasic, tamasic, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                user_id,
                ",".join(answers),
                baseline,
                sattvic,
                rajasic,
                tamasic,
                datetime.utcnow().isoformat(),
            ),
        )
        return cur.lastrowid


def get_vpi_history(user_id: str = "default", limit: int = 20) -> List[Dict[str, Any]]:
    """Return the most recent VPI sessions for a user."""
    with get_connection() as conn:
        rows = conn.execute(
            """SELECT * FROM vpi_sessions
               WHERE user_id = ?
               ORDER BY id DESC LIMIT ?""",
            (user_id, limit),
        ).fetchall()
    return [dict(r) for r in rows]



def save_voice_session(
    vpi_baseline: str,
    guna_state: str,
    sattvic_score: float,
    rajasic_score: float,
    tamasic_score: float,
    transcript: Optional[str] = None,
    prescription: Optional[str] = None,
    file_size_bytes: Optional[int] = None,
    user_id: str = "default",
) -> int:
    """Insert a voice analysis session and return the new row id."""
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO voice_sessions
               (user_id, vpi_baseline, guna_state, sattvic_score, rajasic_score,
                tamasic_score, transcript, prescription, file_size_bytes, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                user_id,
                vpi_baseline,
                guna_state,
                round(sattvic_score, 4),
                round(rajasic_score, 4),
                round(tamasic_score, 4),
                transcript,
                prescription,
                file_size_bytes,
                datetime.utcnow().isoformat(),
            ),
        )
        return cur.lastrowid


def get_voice_history(user_id: str = "default", limit: int = 20) -> List[Dict[str, Any]]:
    """Return the most recent voice sessions for a user."""
    with get_connection() as conn:
        rows = conn.execute(
            """SELECT * FROM voice_sessions
               WHERE user_id = ?
               ORDER BY id DESC LIMIT ?""",
            (user_id, limit),
        ).fetchall()
    return [dict(r) for r in rows]


def get_all_stats() -> Dict[str, Any]:
    """Return aggregate counts for the admin/status endpoint."""
    with get_connection() as conn:
        vpi_count = conn.execute("SELECT COUNT(*) FROM vpi_sessions").fetchone()[0]
        voice_count = conn.execute("SELECT COUNT(*) FROM voice_sessions").fetchone()[0]
        guna_dist = conn.execute(
            "SELECT guna_state, COUNT(*) as cnt FROM voice_sessions GROUP BY guna_state"
        ).fetchall()
    return {
        "total_vpi_sessions": vpi_count,
        "total_voice_sessions": voice_count,
        "guna_distribution": {row["guna_state"]: row["cnt"] for row in guna_dist},
    }
