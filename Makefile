.PHONY: build
build:
	rm -r ./build && mkdir ./build; \
	cp -r ./src/* ./build; \
	pip install -r requirements.txt -t ./build;
