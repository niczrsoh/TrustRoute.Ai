from __future__ import annotations

from typing import Any

from .config import settings


CONTRACT_ABI = [
    {
        "inputs": [
            {"internalType": "bytes32", "name": "shipmentHash", "type": "bytes32"},
            {"internalType": "bytes32", "name": "evidenceHash", "type": "bytes32"},
            {"internalType": "enum DefectReportRegistry.DefectType", "name": "defectType", "type": "uint8"},
            {"internalType": "uint16", "name": "confidenceBps", "type": "uint16"},
            {"internalType": "uint64", "name": "detectedAt", "type": "uint64"},
        ],
        "name": "anchorReport",
        "outputs": [{"internalType": "uint256", "name": "reportId", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [
            {"internalType": "bytes32", "name": "shipmentHash", "type": "bytes32"},
            {"internalType": "bytes32", "name": "certificateHash", "type": "bytes32"},
            {"internalType": "bytes32", "name": "recipientHash", "type": "bytes32"},
            {"internalType": "bytes32", "name": "conditionHash", "type": "bytes32"},
            {"internalType": "uint64", "name": "deliveredAt", "type": "uint64"},
        ],
        "name": "issueDeliveryCertificate",
        "outputs": [{"internalType": "uint256", "name": "certificateId", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
]


class BlockchainNotConfigured(RuntimeError):
    pass


def is_blockchain_configured() -> bool:
    return bool(settings.ethereum_rpc_url and settings.ethereum_private_key and settings.defect_registry_address)


def send_anchor_report(payload: dict[str, Any]) -> str:
    contract = _contract()
    function_call = contract.functions.anchorReport(
        payload["shipment_hash"],
        payload["evidence_hash"],
        int(payload["defect_type_chain_id"]),
        int(payload["confidence_bps"]),
        int(payload["detected_at_unix"]),
    )
    return _send_transaction(function_call)


def send_delivery_certificate(payload: dict[str, Any]) -> str:
    contract = _contract()
    function_call = contract.functions.issueDeliveryCertificate(
        payload["shipment_hash"],
        payload["certificate_hash"],
        payload["recipient_hash"],
        payload["condition_hash"],
        int(payload["delivered_at_unix"]),
    )
    return _send_transaction(function_call)


def _contract() -> Any:
    if not is_blockchain_configured():
        raise BlockchainNotConfigured(
            "Set ETH_RPC_URL, ETH_PRIVATE_KEY, and DEFECT_REGISTRY_ADDRESS to submit transactions."
        )

    try:
        from web3 import Web3
    except ImportError as exc:
        raise BlockchainNotConfigured("Install web3 to submit Ethereum transactions.") from exc

    web3 = Web3(Web3.HTTPProvider(settings.ethereum_rpc_url))
    if not web3.is_connected():
        raise BlockchainNotConfigured("Unable to connect to ETH_RPC_URL.")

    address = web3.to_checksum_address(settings.defect_registry_address)
    return web3.eth.contract(address=address, abi=CONTRACT_ABI)


def _send_transaction(function_call: Any) -> str:
    try:
        from web3 import Web3
    except ImportError as exc:
        raise BlockchainNotConfigured("Install web3 to submit Ethereum transactions.") from exc

    web3 = Web3(Web3.HTTPProvider(settings.ethereum_rpc_url))
    account = web3.eth.account.from_key(settings.ethereum_private_key)
    nonce = web3.eth.get_transaction_count(account.address)
    transaction = function_call.build_transaction(
        {
            "from": account.address,
            "chainId": settings.ethereum_chain_id,
            "nonce": nonce,
            "gas": 300000,
            "gasPrice": web3.eth.gas_price,
        }
    )
    signed = web3.eth.account.sign_transaction(transaction, settings.ethereum_private_key)
    tx_hash = web3.eth.send_raw_transaction(signed.raw_transaction)
    return web3.to_hex(tx_hash)
