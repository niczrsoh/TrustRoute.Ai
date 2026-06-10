from app.ai.granite_vision import GraniteVisionClassifier


def test_granite_parser_normalizes_json_result() -> None:
    classifier = GraniteVisionClassifier("ibm-granite/granite-vision-3.2-2b")

    prediction = classifier._parse_prediction(
        """
        {
          "defect_type": "crushed",
          "confidence": 0.81,
          "item_type": "cardboard parcel",
          "damage_location": "front-left corner",
          "explanation": "The parcel corner appears compressed."
        }
        """
    )

    assert prediction.defect_type == "crushed"
    assert prediction.confidence == 0.81
    assert prediction.item_type == "cardboard parcel"
    assert prediction.damage_location == "front-left corner"
    assert prediction.scores["crushed"] == 0.81
