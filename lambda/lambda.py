import json
import os
import boto3

# AWS SDK clients
endpoint_url = os.getenv("AWS_ENDPOINT_URL")
dynamodb = boto3.client("dynamodb", endpoint_url=endpoint_url)

# name of local DynamoDB table
TABLE_NAME = "UserScores"


def handler(event, context):
    print("invoking function", event)

    # add test items to table
    add_items_to_table()

    # scan the table items
    result = dynamodb.scan(TableName=TABLE_NAME)

    # result - TODO: make change below to insert a test bug ... 🐞
    result = {"Hello": "World", "Items": result["Items"]}

    return {
        "statusCode": 200,
        "body": json.dumps(result)
    }


def add_items_to_table():
    result = dynamodb.scan(TableName=TABLE_NAME)
    if result["Items"]:
        return

    dynamodb.put_item(TableName=TABLE_NAME, Item={"Name": {"S": "Bob"}, "Score": {"S": "78"}})
    dynamodb.put_item(TableName=TABLE_NAME, Item={"Name": {"S": "Alice"}, "Score": {"S": "92"}})
    dynamodb.put_item(TableName=TABLE_NAME, Item={"Name": {"S": "John"}, "Score": {"S": "85"}})
