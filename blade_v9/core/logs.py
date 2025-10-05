# Blade v9 - core.logs
# Logger simple de session : fichier horodaté + console, helpers de timing.

from __future__ import annotations
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from datetime import datetime
from time import perf_counter
from typing import Optional, Dict


_LOGGER: Optional[logging.Logger] = None
_LOG_PATH: Optional[Path] = None
_TIMERS: Dict[str, float] = {}


def _default_log_dir() -> Path:
    # Ex: C:\Users\<user>\blade_logs
    home = Path.home()
    return home / "blade_logs"


def setup_session_logger(name: str = "blade_v9", level: int = logging.INFO) -> tuple[logging.Logger, Path]:
    """Initialise un logger de session (console + fichier horodaté).
       Retourne (logger, chemin_du_fichier). Idempotent : réutilise le logger existant.
    """
    global _LOGGER, _LOG_PATH
    if _LOGGER:
        return _LOGGER, _LOG_PATH

    log_dir = _default_log_dir()
    log_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    _LOG_PATH = log_dir / f"{name}_{stamp}.log"

    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.propagate = False  # pas de double log

    # Console
    ch = logging.StreamHandler()
    ch.setLevel(level)
    ch.setFormatter(logging.Formatter("[Blade v9] %(levelname)s: %(message)s"))

    # Fichier (rotation 5 x 5 Mo par prudence)
    fh = RotatingFileHandler(_LOG_PATH, maxBytes=5 * 1024 * 1024, backupCount=5, encoding="utf-8")
    fh.setLevel(level)
    fh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))

    logger.addHandler(ch)
    logger.addHandler(fh)

    logger.info(f"Session log started: {_LOG_PATH}")
    _LOGGER = logger
    return logger, _LOG_PATH


def get_logger() -> logging.Logger:
    if not _LOGGER:
        setup_session_logger()
    return _LOGGER


def start_timer(key: str):
    _TIMERS[key] = perf_counter()


def end_timer(key: str, logger: Optional[logging.Logger] = None, label: Optional[str] = None):
    t0 = _TIMERS.pop(key, None)
    if t0 is None:
        return
    dt = (perf_counter() - t0) * 1000.0
    msg = f"{label or key} took {dt:.2f} ms"
    (logger or get_logger()).info(msg)
