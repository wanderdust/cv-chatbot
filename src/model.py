from transformers import pipeline


class ChatBot:
    def __init__(self):
        self.context = self.load_context()
        self.model = self.load_model()

    def load_context(self):
        with open("data/context.txt", "r") as f:
            return f.read()

    def load_model(self):
        return pipeline(
            "question-answering",
            model="models/roberta-base-squad2",
            tokenizer="models/roberta-base-squad2",
        )

    def predict(self, question):
        return self.model(question=question, context=self.context)["answer"]
