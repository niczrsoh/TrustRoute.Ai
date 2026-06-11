from app.blockchain import build_blockchain_fields, confidence_to_bps, keccak_hex


def test_keccak_hex_matches_ethereum_empty_string_hash() -> None:
    assert keccak_hex("") == "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"


def test_confidence_to_bps() -> None:
    assert confidence_to_bps(0.8351) == 8351
    assert confidence_to_bps(1.25) == 10000
    assert confidence_to_bps(-0.1) == 0


def test_freeform_defect_maps_to_other_chain_id() -> None:
    fields = build_blockchain_fields(
        {
            "id": 1,
            "shipment_id": "SHIP-001",
            "defect_type": "crushed_package",
            "confidence": 0.7,
            "created_at": "2026-06-10T00:00:00+00:00",
            "image_hash": "0xabc",
            "model_name": "ibm-granite/granite-vision-3.2-2b",
        }
    )

    assert fields["defect_type_chain_id"] == 4
