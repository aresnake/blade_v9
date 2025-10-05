# -*- coding: utf-8 -*-
import logging, os, datetime

_LOG_DIR = os.path.join(os.path.expanduser("~"), "blade_logs")
os.makedirs(_LOG_DIR, exist_ok=True)
_LOG_PATH = os.path.join(_LOG_DIR, "blade_v8.log")

_logger = None

def get_logger():
    global _logger
    if _logger:
        return _logger
    logger = logging.getLogger("blade_v8")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        fh = logging.FileHandler(_LOG_PATH, encoding="utf-8")
        fmt = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")
        fh.setFormatter(fmt)
        logger.addHandler(fh)
        sh = logging.StreamHandler()
        sh.setFormatter(fmt)
        logger.addHandler(sh)
    _logger = logger
    logger.info("[Blade v9] Logger ready â†’ %s", _LOG_PATH)
    return _logger



