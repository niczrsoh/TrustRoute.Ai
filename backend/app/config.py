from dataclasses import dataclass
from pathlib import Path
import os
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


@dataclass(frozen=True)
class Settings:
    app_name: str = "SLT Defect Detection API"
    data_dir: Path = Path(os.getenv("SLT_DATA_DIR", BASE_DIR / "data"))
    max_upload_bytes: int = int(os.getenv("SLT_MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
    classifier_backend: str = os.getenv("SLT_CLASSIFIER_BACKEND", "granite")
    classifier_fallback_enabled: bool = os.getenv("SLT_CLASSIFIER_FALLBACK", "true").lower() in {
        "1",
        "true",
        "yes",
    }
    granite_model_id: str = os.getenv("SLT_GRANITE_MODEL_ID", "ibm-granite/granite-vision-3.2-2b")
    granite_trust_remote_code: bool = os.getenv("SLT_GRANITE_TRUST_REMOTE_CODE", "false").lower() in {
        "1",
        "true",
        "yes",
    }
    granite_max_new_tokens: int = int(os.getenv("SLT_GRANITE_MAX_NEW_TOKENS", "8"))
    ethereum_rpc_url: str | None = os.getenv("ETH_RPC_URL")
    ethereum_private_key: str | None = os.getenv("ETH_PRIVATE_KEY")
    ethereum_chain_id: int = int(os.getenv("ETH_CHAIN_ID", "11155111"))
    defect_registry_address: str | None = os.getenv("DEFECT_REGISTRY_ADDRESS")
    auto_anchor_reports: bool = os.getenv("SLT_AUTO_ANCHOR_REPORTS", "true").lower() in {
        "1",
        "true",
        "yes",
    }

    @property
    def upload_dir(self) -> Path:
        return self.data_dir / "uploads"

    @property
    def db_path(self) -> Path:
        return self.data_dir / "defect_reports.sqlite3"


settings = Settings()
