export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1

VENV_DIR ?= .venv
VENV_ACTIVATE = $(VENV_DIR)/bin/activate
VENV_RUN = . $(VENV_ACTIVATE)

SHELL := /bin/bash

usage:    ## Show this help
		@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

install:  ## Install dependencies
		@which localstack || pip install localstack
		@which awslocal || pip install awscli-local
		@which tflocal || pip install terraform-local
		test -e .venv/bin/activate || python -m venv $(VENV_DIR)
		$(VENV_RUN); pip install -r requirements.txt

start:    ## Start LocalStack in detached mode
		$(VENV_RUN); DEBUG=1 localstack start -d; localstack wait -t 60 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

stop:     ## Stop the Running LocalStack container
		@echo
		localstack stop

ready:    ## Make sure the LocalStack container is up
		@echo Waiting on the LocalStack container...
		@localstack wait -t 30 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

deploy:   ## Deploy the application via Terraform
		@tflocal init
		@tflocal apply -auto-approve

deploy-real-aws:  ## Deploy the application to real AWS Cloud (requires valid credentials)
		(cd lambda; zip -r ../lambda.zip .)
		terraform init
		TF_VAR_is_local=false terraform apply -auto-approve

invoke:   ## Invoke the Lambda via API Gateway
		curl http://testapi.execute-api.localhost.localstack.cloud:4566/

test:     ## Run the integration tests
		$(VENV_RUN); pytest tests

logs:     ## Save the LocalStack logs in a separate file
		@localstack logs > logs.txt

.PHONY: usage install run start stop ready logs
