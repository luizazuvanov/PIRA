<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-pira_logo_dark.png">
    <img alt="nf-core/pira" src="docs/images/nf-core-pira_logo_light.png">
  </picture>
</h1>

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new/nf-core/pira)
[![GitHub Actions CI Status](https://github.com/nf-core/pira/actions/workflows/nf-test.yml/badge.svg)](https://github.com/nf-core/pira/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/pira/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/pira/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/pira/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.04.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.4.1-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.4.1)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/pira)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23pira-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/pira)[![Follow on Bluesky](https://img.shields.io/badge/bluesky-%40nf__core-1185fe?labelColor=000000&logo=bluesky)](https://bsky.app/profile/nf-co.re)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/pira** is a bioinformatics pipeline to identifying RNA alternatives.

![nf-core/pira metro map](docs/images/nf-core-pira_map_light.svg)

1. Reference genome:
   1. Use or compute genome index with [STAR](https://physiology.med.cornell.edu/faculty/skrabanek/lab/angsd/lecture_notes/STARmanual.pdf);
   2. Compute `BED` file with [UCSC tools](https://genome.ucsc.edu/goldenPath/help/hgTablesHelp.html).
2. Samples:
   1. Use or download sample data from `SRA` with NCBI's [SRA Toolkit](https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump).
3. Quality control and trimming with [FASTP](https://github.com/OpenGene/fastp);
4. Alignment and quantification with [STAR](https://physiology.med.cornell.edu/faculty/skrabanek/lab/angsd/lecture_notes/STARmanual.pdf);
5. Sort and index `BAM` files with [SAMtools](http://www.htslib.org/);
6. Alignment quality control with [RSeQC](http://rseqc.sourceforge.net/);
7. Transcript assembly and merge with [StringTie2](https://ccb.jhu.edu/software/stringtie/);
8. Alternative splicing analysis with [rMATS](http://rnaseq-mats.sourceforge.net/).

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
run,experiment,condition,fastq_1,fastq_2
SRR16496056,SRX12699021,COND1,SRR16496056_1.fastq.gz,SRR16496056_2.fastq.gz
SRR16496066,SRX12699031,COND2,SRR16496066_1.fastq.gz,SRR16496066_2.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end). For aligment, rows with 'runs' with
the same `experiment` value will be treated as replicates of the same experiment and merged. Similarly, for alternative
splicing analysis, rows with the same `condition` value will be treated as replicates of the same condition.

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run nf-core/pira \
   -profile <docker/singularity/.../institute> \
   --input "samplesheet.csv" \
   --outdir <OUTDIR> \
   --with_fastq \
   --fasta <FASTA> \
   --gtf <GTF> \
   --index <INDEX_DIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/pira/usage) and the [parameter documentation](https://nf-co.re/pira/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/pira/results)
tab on the nf-core website pipeline page. For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/pira/output).

## Credits

These scripts were originally written by [Luíza Zuvanov](@luizazuvanov). The pipeline was re-written in Nextflow DSL2 by
[Andre Perez](@andre-marcos-perez) and is currently maintained by [Luíza Zuvanov](@luizazuvanov),
[Andre Perez](@andre-marcos-perez) and the nf-core community.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the
[Slack `#pira` channel](https://nfcore.slack.com/channels/pira) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/pira for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
