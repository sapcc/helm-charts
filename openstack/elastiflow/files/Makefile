# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))


# HELP
# This will output the help for each task
# reference: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

# HELP

help:
	@echo "Usage: make [cnf=your_config.env] [options] \n"
	@echo 'Options:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# DOCKER TASKS

build: ## Build Container
	docker build -t elastiflow-logstash-oss .

# VERSION is according to https://semver.org/#backusnaur-form-grammar-for-valid-semver-versions
tag: ## Tag Image with latest versions
	@echo 'create tag latest'
	docker tag elastiflow-logstash-oss $(DOCKER_REPO)/elastiflow-logstash-oss:latest
	@echo 'create tag $(VERSION)'
	docker tag elastiflow-logstash-oss $(DOCKER_REPO)/elastiflow-logstash-oss:$(VERSION)