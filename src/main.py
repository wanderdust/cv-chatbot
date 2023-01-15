import json
import traceback

from models import ChatBot, IntentDetector

chatbot = ChatBot()
intent_detector = IntentDetector()


def response(response, status_code=200):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
        },
        "body": json.dumps(response),
    }


def handler(event, context):
    message = event["queryStringParameters"]["message"]
    try:
        intent = intent_detector(message)
        return response(chatbot(message, intent))
    except Exception:
        raise Exception(traceback.format_exc())


if __name__ == "__main__":
    question = "What are his hobbies?"
    res = handler({"queryStringParameters": {"message": question}}, None)
    print(res["body"])
