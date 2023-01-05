import json
import traceback

from models import ChatBot, GreetingDetector

chatbot = ChatBot()


def response(response):
    return {"statusCode": 200, "body": json.dumps(response)}


def handler(event, context):
    message = json.loads(event["body"])["message"]
    try:
        if GreetingDetector.is_greeting(message):
            return response(GreetingDetector.default_response())

        return response(chatbot.predict(message))
    except Exception:
        raise Exception(traceback.format_exc())


if __name__ == "__main__":
    print(handler({"body": '{"message": "What does he do at Zonda?"}'}, None))
