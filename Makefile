.PHONY: help
help: ## Show this help message
	@grep -h -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Lint code
	@pre-commit run --all-files

.PHONY: build
build: ## Build pipeline deps container
	@docker build --no-cache . -t nfcore/pira:dev

.PHONY: test
test: ## Run test
	@make clean
	@nextflow -log ./logs/.nextflow.log \
		run main.nf \
		-profile test,docker \
		-stub-run \
		--outdir ./results

.PHONY: debug
debug: ## Run test with debug profile
	@make clean
	@nextflow -log ./logs/.nextflow.log \
		run main.nf \
		-profile debug,test,docker \
		-stub-run \
		--outdir ./results

.PHONY: run
run: ## Run pipeline
	@nextflow -log ./logs/.nextflow.log \
		run main.nf \
		-profile docker \
		--input ./assets/samplesheet.csv \
		--outdir ./results

.PHONEY: clean
clean: ## Clean up
	@rm -rf ./results ./logs/.nextflow.log* ./work