import json

import requests

from tests.config import API_URL


def test_invoke_lambda():
    result = requests.get(API_URL)
    payload = json.loads(result.content)
    assert payload["Hello"] == "World"
