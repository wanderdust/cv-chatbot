import openai


class ChatBot:
    def __init__(self):
        self.context = self.load_context()
        self.bot_role = (
            "You are a helpful assistant called BillyBot that answers "
            "questions about Pablo's CV. Answer as concisely as possible, keeping responses short"
        )

    def __call__(self, message):
        return self.chat(message)

    def chat(self, message):
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": f"{self.bot_role}: {self.context}"},
                {"role": "user", "content": message},
            ],
        )

        return response["choices"][0]["message"]["content"]

    def load_context(self):
        with open("data/pablo_context.txt", "r") as f:
            return f.read()
