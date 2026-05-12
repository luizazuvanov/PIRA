# nf-core/pira: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/pira/usage](https://nf-co.re/pira/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

nf-core/pira is a pipeline for event-based alternative splicing analysis from bulk RNA-seq data. It covers the full workflow from raw FASTQ files (or NCBI SRA accession IDs) to differential splicing results produced by rMATS-turbo. The sections below describe how to prepare your inputs, run the pipeline, and customise its behaviour.

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location.

```bash
--input '[path to samplesheet file]'
```

The samplesheet must be a comma-separated file with a header row. The six supported columns are described in the table below. The `run`, `experiment`, `condition`, and `single_end` columns are **always required**. The `fastq_1` and `fastq_2` columns are required only when `--with_fastq` is set; when starting from NCBI SRA accession IDs they can be omitted.

| Column       | Required                     | Description                                                                                                                                                                                                 |
| ------------ | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `run`        | Always                       | Unique run identifier. Use an NCBI SRA Run accession (e.g. `SRR16496056`) to download data automatically, or any alphanumeric string (e.g. `sample-1`) when providing local FASTQ files with `--with_fastq`. |
| `experiment` | Always                       | NCBI SRA Experiment accession (e.g. `SRX12699021`) or a custom alphanumeric label. Runs sharing the same `experiment` value are merged before alignment and treated as technical replicates.                  |
| `condition`  | Always                       | Condition label used to group biological replicates (e.g. `CTRL`, `TREAT`). All experiments belonging to the same condition are pooled for the alternative splicing analysis.                                 |
| `single_end` | Always                       | `true` for single-end libraries, `false` for paired-end.                                                                                                                                                      |
| `fastq_1`    | Only with `--with_fastq`     | Absolute or relative path to the gzipped FASTQ file for read 1 (extension must be `.fastq.gz` or `.fq.gz`).                                                                                                   |
| `fastq_2`    | Only with `--with_fastq` (PE) | Absolute or relative path to the gzipped FASTQ file for read 2 (paired-end only). Leave empty for single-end libraries.                                                                                      |

### Starting from local FASTQ files

When your data is already on disk, set the `--with_fastq` flag and provide paths in the `fastq_1` / `fastq_2` columns:

```csv title="samplesheet.csv"
run,experiment,condition,single_end,fastq_1,fastq_2
SRR16496056,SRX12699021,0DY,false,/data/fastq/SRR16496056_1.fastq.gz,/data/fastq/SRR16496056_2.fastq.gz
SRR16496057,SRX12699022,0DY,false,/data/fastq/SRR16496057_1.fastq.gz,/data/fastq/SRR16496057_2.fastq.gz
SRR16496058,SRX12699023,0DY,false,/data/fastq/SRR16496058_1.fastq.gz,/data/fastq/SRR16496058_2.fastq.gz
SRR16496066,SRX12699031,9DA,false,/data/fastq/SRR16496066_1.fastq.gz,/data/fastq/SRR16496066_2.fastq.gz
SRR16496067,SRX12699032,9DA,false,/data/fastq/SRR16496067_1.fastq.gz,/data/fastq/SRR16496067_2.fastq.gz
SRR16496068,SRX12699033,9DA,false,/data/fastq/SRR16496068_1.fastq.gz,/data/fastq/SRR16496068_2.fastq.gz
```

In this example there are two conditions (`0DY` and `9DA`), each with three biological replicates. Each replicate is a distinct experiment, and each experiment has a single run.

### Starting from NCBI SRA accessions

When `--with_fastq` is **not** set, the pipeline uses the `run` column as an NCBI SRA Run accession and downloads the corresponding FASTQ files automatically via SRA Toolkit. The `fastq_1` and `fastq_2` columns can be omitted:

```csv title="samplesheet.csv"
run,experiment,condition,single_end
SRR16496056,SRX12699021,0DY,false
SRR16496057,SRX12699022,0DY,false
SRR16496058,SRX12699023,0DY,false
SRR16496066,SRX12699031,9DA,false
SRR16496067,SRX12699032,9DA,false
SRR16496068,SRX12699033,9DA,false
```

> [!TIP]
> NCBI may require credentials or an API key for large downloads. See the [SRA Toolkit documentation](https://github.com/ncbi/sra-tools/wiki) for setup instructions.

### Multiple runs per experiment (technical replicates)

If a single experiment was sequenced across multiple runs (e.g. multiple flow-cell lanes), list each run as a separate row with the same `experiment` value. The pipeline merges their reads automatically before alignment:

```csv title="samplesheet.csv"
run,experiment,condition,single_end,fastq_1,fastq_2
SRR16496056,SRX12699021,CTRL,false,SRR16496056_1.fastq.gz,SRR16496056_2.fastq.gz
SRR16496057,SRX12699021,CTRL,false,SRR16496057_1.fastq.gz,SRR16496057_2.fastq.gz
SRR16496058,SRX12699022,TREAT,false,SRR16496058_1.fastq.gz,SRR16496058_2.fastq.gz
```

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

## Running the pipeline

### Minimal run with local FASTQ files

```bash
nextflow run nf-core/pira \
   -profile docker \
   --input samplesheet.csv \
   --outdir ./results \
   --with_fastq \
   --fasta /data/genome.fa \
   --gtf /data/annotation.gtf
```

### Minimal run downloading data from NCBI SRA

```bash
nextflow run nf-core/pira \
   -profile docker \
   --input samplesheet.csv \
   --outdir ./results \
   --fasta /data/genome.fa \
   --gtf /data/annotation.gtf
```

### Re-using a pre-built STAR index

If you have already built a STAR genome index, pass it with `--index` to skip index generation:

```bash
nextflow run nf-core/pira \
   -profile docker \
   --input samplesheet.csv \
   --outdir ./results \
   --with_fastq \
   --fasta /data/genome.fa \
   --gtf /data/annotation.gtf \
   --index /data/star_index/
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/pira -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
with_fastq: true
fasta: '/data/genome.fa'
gtf: '/data/annotation.gtf'
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Pipeline-specific options

| Parameter                 | Default | Description                                                                                                                                |
| ------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `--with_fastq`            | `false` | Use FASTQ files from the samplesheet. When not set, the pipeline downloads reads from NCBI SRA using the `run` accession ID.              |
| `--with_twopass`          | `true`  | Run STAR's two-pass alignment. The baseline pass discovers splice junctions that are fed back into a second, more sensitive alignment step. |
| `--with_transcriptassembly` | `true` | Assemble per-experiment transcripts with StringTie2 and merge them into a consensus GTF before running rMATS.                             |
| `--with_novelss`          | `true`  | Enable rMATS novel splice-site detection (`--novelSS --mil 30`). Increases sensitivity but also run time.                                 |

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/pira
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/pira releases page](https://github.com/nf-core/pira/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

> [!NOTE]
> STAR genome index generation is memory intensive. For a human-sized genome (~3 Gb) you will need approximately 40 GB of RAM.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
