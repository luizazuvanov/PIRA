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

.PHONY: refactor-local
refactor-local: ## Refactor pipeline for local testing
	@git checkout subworkflows/local/ID4/main.nf
	@sed -i '' -e "s/it.bam,/it.bam.findAll { it.name.endsWith('.Aligned.sortedByCoord.out.bam')},/g" subworkflows/local/ID4/main.nf

.PHONY: rollback-local
rollback-local: ## Rollback pipeline refactor for local testing
	@git checkout -- subworkflows/local/ID4/main.nf

.PHONY: resume
resume: ## Resume test
	@nextflow -log ./logs/nextflow.log \
		run main.nf \
		-profile stub,docker \
		-stub-run \
		-resume \
		-with-dag ./results/pipeline_info/pipeline.mmd \
		--outdir ./results

.PHONY: resume-with-flags
resume-with-flags: ## Resume test with flags
	@nextflow -log ./logs/nextflow.log \
		run main.nf \
		-profile stub,docker \
		-stub-run \
		-resume \
		-with-dag ./results/pipeline_info/pipeline.mmd \
		--with_fastq \
		--with_twopass false \
		--with_novelss false \
		--with_transcriptassembly false \
		--index ./assets/data/index/ \
		--outdir ./results

.PHONY: run
run: ## Run pipeline
	@make clean
	@make refactor-local
	@make resume
	@make rollback-local

.PHONY: run-with-flags
run-with-flags: ## Run pipeline with flags
	@make clean
	@make refactor-local
	@make resume-with-flags
	@make rollback-local

.PHONY: test
test: ## Run tests
	@./bin/nf-test clean
	@./bin/nf-test test --clean-snapshot
