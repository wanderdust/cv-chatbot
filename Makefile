download_model:
	git lfs install && git clone https://huggingface.co/deepset/minilm-uncased-squad2 src/models/minilm-uncased-squad2

src/models/minilm-uncased-squad2/config.json:
	make download_model

build: src/models/minilm-uncased-squad2/config.json
	docker build -t pablo-cv-chatbot .
