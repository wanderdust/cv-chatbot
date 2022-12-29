download_roberta:
	git lfs install && git clone https://huggingface.co/deepset/roberta-base-squad2 src/models/roberta-base-squad2

download_classifier:
	git lfs install && git clone https://huggingface.co/facebook/bart-large-mnli src/models/bart-zero-shot-classifier
