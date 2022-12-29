import random
from dataclasses import dataclass

from transformers import pipeline


class ChatBot:
    def __init__(self):
        self.model = self.load_model()

    def load_context(self, context_path):
        with open(f"data/{context_path}.txt", "r") as f:
            return f.read()

    def load_model(self):
        return pipeline(
            "question-answering",
            model="models/roberta-base-squad2",
            tokenizer="models/roberta-base-squad2",
        )

    def predict(self, question, context_name="pablo_context"):
        context = self.load_context(context_name)
        return self.model(question=question, context=context)["answer"]


class GreetingDetector:
    def is_greeting(message):
        greetings = ["hi ", "hi,", "hello", "hey"]
        return any(greeting in message.lower() for greeting in greetings)

    def default_response():
        greet = random.choice(["Hello", "Hi", "Hey"])
        return (
            f"{greet}! I am a chatbot knows a lot about Pablo's CV. "
            "Try asking me something like: 'What is Pablo's current role?"
        )
