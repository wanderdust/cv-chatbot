import json
import traceback

from models import ChatBot, GreetingDetector

chatbot = ChatBot()


def response(response, status_code=200):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(response),
    }


def handler(event, context):
    message = event["queryStringParameters"]["message"]
    try:
        if GreetingDetector.is_greeting(message):
            return response(GreetingDetector.default_response())

        return response(chatbot.predict(message))
    except Exception:
        raise Exception(traceback.format_exc())


if __name__ == "__main__":
    print(handler({"queryStringParameters": {"message": "What does he do at Zonda?"}}, None))
