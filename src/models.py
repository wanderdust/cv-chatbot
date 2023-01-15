import random
from dataclasses import dataclass

from transformers import pipeline


class ChatBot:
    def __init__(self):
        self.model = self.load_model()

    def __call__(self, message, intent):
        if intent == "greeting":
            return self.greeting()
        if intent == "question_about_me":
            return self.answer(message, context_name="pablo_context")
        if intent == "question_to_bot":
            return self.answer(message, context_name="bot_context")
        return self.default_response()

    def load_context(self, context_path):
        with open(f"data/{context_path}.txt", "r") as f:
            return f.read()

    def load_model(self):
        return pipeline(
            "question-answering",
            model="models/minilm-uncased-squad2",
            tokenizer="models/minilm-uncased-squad2",
        )

    def answer(self, question, context_name="pablo_context"):
        context = self.load_context(context_name)
        response = self.model(question=question, context=context)["answer"]
        return self.format_response(response)

    def format_response(self, response):
        response = response[0].upper() + response[1:]
        return response

    def greeting(self):
        greet = random.choice(["Hello", "Hi", "Hey"])
        return (
            f"{greet}! I am BillyBot, a chatbot built by Pablo. "
            "I can answer questions about him."
        )

    def default_response(self):
        possible_examples = [
            "What is Pablo's current role?",
            "What was his previous role?",
            "What does Pablo do at Zonda?",
            "What are his hobbies?",
        ]
        return f"Sorry, I don't understand your question. Try asking me something like: {random.choice(possible_examples)}'"


@dataclass
class IntentDetector:
    def __call__(self, message):
        if self.is_greeting(message):
            return "greeting"
        if self.is_question_about_me(message):
            return "question_about_me"
        if self.is_question_to_bot(message):
            return "question_to_bot"
        return "other"

    def is_greeting(self, message):
        greetings = ["hi ", "hi,", "hello", "hey"]
        return any(greeting in message.lower() for greeting in greetings)

    def is_question_about_me(self, message):
        keywords = [" he", " his", " him", "pablo"]
        return any(keyword in message.lower() for keyword in keywords)

    def is_question_to_bot(self, message):
        keywords = ["you", "your", "bot"]
        return any(keyword in message.lower() for keyword in keywords)
