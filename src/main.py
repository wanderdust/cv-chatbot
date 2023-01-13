import json
import traceback

from models import ChatBot, GreetingDetector

chatbot = ChatBot()


def response(response):
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Credentials": True,
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
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
