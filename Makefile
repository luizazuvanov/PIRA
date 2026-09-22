.PHONY: help
help: ## Show this help message
	@grep -h -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Lint code
	@pre-commit run --all-files

.PHONY: nfcore-lint
nfcore-lint: ## Lint code with nf-core tools
	@nf-core pipelines lint

.PHONY: build
build: ## Build pipeline deps container
	@docker build --no-cache . -t nfcore/pira:dev

.PHONY: clean
clean: ## Clean up
	@rm -rf ./results ./logs/nextflow.log* ./work ./.nextflow

.PHONY: resume
resume: ## Resume test
	@nextflow -log ./logs/nextflow.log \
		run main.nf \
		-profile stub,docker \
		-stub-run \
		-resume \
		--outdir ./results

.PHONY: resume-with-flags
resume-with-flags: ## Resume test with flags
	@nextflow -log ./logs/nextflow.log \
		run main.nf \
		-profile stub,docker \
		-stub-run \
		-resume \
		-params-file ./assets/params.yml \
		--index ./assets/data/index/ \
		--outdir ./results

.PHONY: run
run: ## Run pipeline
	@make clean
	@make resume

.PHONY: run-with-flags
run-with-flags: ## Run pipeline with flags
	@make clean
	@make resume-with-flags

.PHONY: test
test: ## Run tests
	@./bin/nf-test clean
	@./bin/nf-test test --clean-snapshot
