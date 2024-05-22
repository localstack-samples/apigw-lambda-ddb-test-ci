import json

import requests

from tests.config import API_URL


def test_invoke_lambda_via_api_gateway():
    result = requests.get(API_URL)
    payload = json.loads(result.content)
    assert payload["Hello"] == "World"
