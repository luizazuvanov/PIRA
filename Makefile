.PHONY: help
help: ## Show this help message
	@grep -h -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Lint code
	@pre-commit run --all-files

.PHONY: build
build: ## Build pipeline deps container
	@docker build --no-cache . -t nfcore/pira:dev

.PHONY: render
render: ## Render pipeline
	@make clean
	@nextflow -log ./logs/.nextflow.log \
		run main.nf \
		-profile test,docker \
		-stub-run \
		-preview \
		-with-dag ./results/pipeline_info/pipeline.png \
		--outdir ./results

.PHONY: resume
resume: ## Resume test
	@nextflow -log ./logs/.nextflow.log \
		run main.nf \
		-profile test,docker \
		-stub-run \
		-resume \
		-with-dag ./results/pipeline_info/pipeline.png \
		--outdir ./results

.PHONY: test
test: ## Run test
	@make clean
	@make resume

.PHONY: debug
debug: ## Run test with debug profile
	@make clean
	@nextflow -log ./logs/.nextflow.log \
		run main.nf \
		-profile debug,test,docker \
		-stub-run \
		-with-dag ./results/pipeline_info/pipeline.png \
		--outdir ./results

.PHONY: clean
clean: ## Clean up
	@rm -rf ./results ./logs/.nextflow.log* ./work