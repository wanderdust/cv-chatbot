FROM public.ecr.aws/lambda/python:3.9

COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip3 install -r requirements.txt -t ${LAMBDA_TASK_ROOT}

COPY src/ ${LAMBDA_TASK_ROOT}

CMD ["main.handler"]
