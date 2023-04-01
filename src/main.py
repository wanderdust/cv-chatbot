import json
import traceback

from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse
from mangum import Mangum
from pydantic import BaseModel

from models import ChatBot

app = FastAPI()
chatbot = ChatBot()


class Message(BaseModel):
    message: str


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


@app.get("/chat")
def chat(message: Message = Depends()):
    try:
        response = chatbot(message.message)
        headers = {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
        }
        return JSONResponse(content=response, headers=headers)

    except Exception:
        raise Exception(traceback.format_exc())


handler = Mangum(app)
