import traceback

from fastapi import FastAPI, HTTPException
from mangum import Mangum
from pydantic import BaseModel

from models import ChatBot, GreetingDetector

app = FastAPI()


class ChatResponse(BaseModel):
    response: str


chatbot = ChatBot()


@app.get("/chat", response_model=ChatResponse)
def root(message: str):
    try:
        if GreetingDetector.is_greeting(message):
            return {"response": GreetingDetector.default_response()}

        return {"response": chatbot.predict(message)}
    except Exception:
        raise HTTPException(status_code=400, detail=traceback.format_exc())


handler = Mangum(app)
