export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

usage:			## Show this help in table format
	@echo "| Target                 | Description                                                       |"
	@echo "|------------------------|-------------------------------------------------------------------|"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/:.*##\s*/##/g' | awk -F'##' '{ printf "| %-22s | %-65s |\n", $$1, $$2 }'

check:			## Check if all required prerequisites are installed
	@command -v docker > /dev/null 2>&1 || { echo "Docker is not installed. Please install Docker and try again."; exit 1; }
	@command -v node > /dev/null 2>&1 || { echo "Node.js is not installed. Please install Node.js and try again."; exit 1; }
	@command -v aws > /dev/null 2>&1 || { echo "AWS CLI is not installed. Please install AWS CLI and try again."; exit 1; }
	@command -v localstack > /dev/null 2>&1 || { echo "LocalStack is not installed. Please install LocalStack and try again."; exit 1; }
	@command -v cdk > /dev/null 2>&1 || { echo "CDK is not installed. Please install CDK and try again."; exit 1; }
	@command -v cdklocal > /dev/null 2>&1 || { echo "cdklocal is not installed. Please install cdklocal and try again."; exit 1; }
	@command -v aws > /dev/null 2>&1 || { echo "AWS CLI is not installed. Please install AWS CLI and try again."; exit 1; }
	@command -v awslocal > /dev/null 2>&1 || { echo "awslocal is not installed. Please install awslocal and try again."; exit 1; }
	@echo "All required prerequisites are available."

install:		## Install all required dependencies
		@if [ ! -d "node_modules" ]; then \
			echo "node_modules not found. Running npm install..."; \
			npm install; \
		fi
		@if [ ! -d "demos/rds-query-fn-code/node_modules" ]; then \
			echo "demos/rds-query-fn-code/node_modules not found. Running npm install..."; \
			npm install --prefix demos/rds-query-fn-code; \
		fi
		@echo "All required dependencies are available."

deploy:			## Deploy the CDK stack
		@echo "Bootstrapping CDK..."
		cdklocal bootstrap
		@echo "Deploying CDK..."
		cdklocal deploy --require-approval never
		@echo "CDK deployed successfully."

test:			## Run the tests
		@echo "Running tests..."
		npm test
		@echo "Tests completed successfully."

run:			## Execute a SQL query through the Lambda function
		@echo "Executing SQL query through Lambda function..."
		@aws_version=$$(aws --version | grep -o "aws-cli/[0-9]*" | cut -d'/' -f2); \
		if [ "$$aws_version" = "2" ]; then \
			echo "Using AWS CLI version 2 command format..."; \
			awslocal lambda invoke \
				--cli-binary-format raw-in-base64-out \
				--function-name my-lambda-rds-query-helper \
				--payload '{"sqlQuery": "select Author from books", "secretName":"/rdsinitexample/rds/creds/mysql-01"}' output; \
		else \
			echo "Using AWS CLI version 1 command format..."; \
			awslocal lambda invoke \
				--function-name my-lambda-rds-query-helper \
				--payload '{"sqlQuery": "select Author from books", "secretName":"/rdsinitexample/rds/creds/mysql-01"}' output; \
		fi
		@echo "Query execution completed. Results:"
		@cat output

start:			## Start LocalStack in detached mode
		@echo "Starting LocalStack..."
		@LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) localstack start -d
		@echo "LocalStack started successfully."

stop:			## Stop LocalStack
		@echo "Stopping LocalStack..."
		@localstack stop
		@echo "LocalStack stopped successfully."

ready:			## Wait for LocalStack to be ready
		@echo Waiting on the LocalStack container...
		@localstack wait -t 30 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

logs:			## Get LocalStack logs
		@localstack logs > logs.txt

.PHONY: usage check start ready install deploy test logs stop
