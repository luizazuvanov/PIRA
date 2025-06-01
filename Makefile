.PHONY: help
help: ## Show this help message
	@grep -h -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Lint code
	@pre-commit run --all-files

.PHONY: test
test:  ## Run test
	@nextflow run . -profile debug,test,docker --outdir .

.PHONY: run
run: ## Run pipeline
	@nextflow run . -profile debug,test,docker --outdir .
