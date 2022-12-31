download_model:
	git lfs install && git clone https://huggingface.co/deepset/minilm-uncased-squad2 src/models/minilm-uncased-squad2

src/models/minilm-uncased-squad2/config.json:
	make download_model

build: src/models/minilm-uncased-squad2/config.json
	docker build -t pablo-cv-chatbot .

authenticate:
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

push: build authenticate
	docker tag pablo-cv-chatbot public.ecr.aws/h9e5k5s6/pablo-cv-chatbot:latest
	docker push public.ecr.aws/h9e5k5s6/pablo-cv-chatbot:latest

deploy: push
	terraform apply
