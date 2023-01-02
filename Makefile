download_model:
	git lfs install && git clone https://huggingface.co/deepset/minilm-uncased-squad2 src/models/minilm-uncased-squad2

src/models/minilm-uncased-squad2/config.json:
	make download_model

build: src/models/minilm-uncased-squad2/config.json
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
	docker build -t pablo-cv-chatbot .

authenticate:
	aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 236212633992.dkr.ecr.eu-west-1.amazonaws.com

push: build authenticate
	docker tag pablo-cv-chatbot:latest 236212633992.dkr.ecr.eu-west-1.amazonaws.com/pablo-cv-chatbot:latest
	docker push 236212633992.dkr.ecr.eu-west-1.amazonaws.com/pablo-cv-chatbot:latest

deploy: push
	terraform apply
