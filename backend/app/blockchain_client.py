from typing import Any

class BlockchainNotConfigured(Exception):
    pass

def send_anchor_report(payload: dict[str, Any]) -> str:
    raise BlockchainNotConfigured("Blockchain client is not fully implemented or configured. File was missing from git.")
