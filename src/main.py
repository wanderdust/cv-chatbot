from fastapi import FastAPI, HTTPException
from mangum import Mangum
from pydantic import BaseModel

from model import ChatBot

app = FastAPI()


class ChatResponse(BaseModel):
    response: str


chatbot = ChatBot()


@app.get("/chat", response_model=ChatResponse)
async def root(message: str):
    try:
        return {"response": chatbot.predict(message)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=e)


handler = Mangum(app)
