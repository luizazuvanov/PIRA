# nf-core/pira: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/pira/usage](https://nf-co.re/pira/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

PIRA is an RNA-seq workflow for identifying and quantifying alternative splicing events, including events that are absent from the supplied reference annotation. The workflow requires a reference FASTA and GTF file and can either download sequencing runs from SRA or use FASTQ files supplied in the samplesheet.

The default workflow performs SRA retrieval, fastp preprocessing, STAR alignment, SAMtools statistics and indexing, RSeQC strandedness inference, rMATS alternative-splicing analysis, and MultiQC reporting. Optional parameters enable STAR two-pass alignment, StringTie transcript assembly, and rMATS novel splice-site detection.

## Samplesheet input

The input samplesheet is a comma-separated file with a header row. Each row represents one sequencing run. The required columns are:

| Column       | Description                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------- |
| `run`        | SRA run accession or custom run identifier.                                                 |
| `experiment` | Experiment identifier used to group runs and report results.                                |
| `condition`  | Condition name used to form comparison groups.                                              |
| `single_end` | `true` for single-end data or `false` for paired-end data.                                  |
| `fastq_1`    | FASTQ read 1 path. Required with `--with_fastq`.                                            |
| `fastq_2`    | FASTQ read 2 path for paired-end data. Required with `--with_fastq` for paired-end samples. |

The first four columns are required in all modes. The FASTQ columns are required only when `--with_fastq` is used. Use the same `condition` value for biological replicates that should be compared. Each run must have a unique `run` identifier.

### SRA input

With the default `--with_fastq` omitted, the `run` column is used to download data through the SRA Toolkit. FASTQ paths may be left empty:

```csv
run,experiment,condition,single_end,fastq_1,fastq_2
SRR16496056,SRX12699021,control,false,,
SRR16496066,SRX12699031,treatment,false,,
```

### FASTQ input

Set `--with_fastq` to use local FASTQ files from the samplesheet. For paired-end data, provide both FASTQ paths:

```csv
run,experiment,condition,single_end,fastq_1,fastq_2
sample-1,experiment-1,control,false,reads/sample-1_R1.fastq.gz,reads/sample-1_R2.fastq.gz
sample-2,experiment-1,treatment,true,reads/sample-2.fastq.gz,
```

An [example samplesheet](../assets/samplesheet.csv) is provided with the repository.

## Reference files

Provide a genome FASTA and matching GTF annotation:

```bash
--fasta /path/to/reference.fa \
--gtf /path/to/annotation.gtf
```

The FASTA and GTF must use matching chromosome or contig names. PIRA automatically generates a STAR genome index when `--index` is omitted. To reuse an existing compatible STAR index, provide:

```bash
--index /path/to/star_index
```

The BED annotation required by RSeQC is generated automatically from the GTF.

## Running the pipeline

The standard command is:

```bash
nextflow run nf-core/pira \
    --input ./samplesheet.csv \
    --fasta ./reference.fa \
    --gtf ./annotation.gtf \
    --outdir ./results \
    -profile docker
```

When using local FASTQ files:

```bash
nextflow run nf-core/pira \
    --input ./samplesheet_fastq.csv \
    --with_fastq \
    --fasta ./reference.fa \
    --gtf ./annotation.gtf \
    --outdir ./results \
    -profile docker
```

Optional discovery layers can be enabled independently:

```bash
--with_twopass
--with_transcriptassembly
--with_novelss
```

To enable all three layers:

```bash
nextflow run nf-core/pira \
    --input ./samplesheet_fastq.csv \
    --with_fastq \
    --with_twopass \
    --with_transcriptassembly \
    --with_novelss \
    --fasta ./reference.fa \
    --gtf ./annotation.gtf \
    --outdir ./results \
    -profile docker
```

The rMATS `--novelSS` behavior can be further tuned through module arguments in a custom configuration file, for example when adapting the minimum intron length for a compact genome.

## Parameter files

Pipeline parameters can be provided in YAML or JSON using `-params-file`:

```bash
nextflow run nf-core/pira \
    -profile docker \
    -params-file params.yml
```

Example:

```yaml
input: "./samplesheet_fastq.csv"
outdir: "./results"
fasta: "./reference.fa"
gtf: "./annotation.gtf"
with_fastq: true
with_twopass: true
with_transcriptassembly: true
with_novelss: true
```

> [!WARNING]
> Do not use `-c` to provide pipeline parameters. Custom config files supplied with `-c` should be used for resource settings, infrastructure options, or module arguments only. Use `-params-file` for pipeline parameters.

## Profiles

PIRA supports the standard nf-core execution profiles:

- `docker`: run processes in Docker containers;
- `singularity` or `apptainer`: run processes in Singularity-compatible containers;
- `podman`, `shifter`, or `charliecloud`: use the corresponding container runtime;
- `conda` or `mamba`: use Conda environments when containers are unavailable;
- `wave`: enable Seqera Wave together with a supported container profile;
- `test`: use the minimal test dataset and test configuration;
- `stub`: run process stubs for fast workflow and channel validation.

Profiles can be combined, for example `-profile test,docker`. Profile order matters because later profiles can override earlier settings.

## Updating the pipeline

When running a released pipeline with `nextflow run nf-core/pira`, Nextflow caches the pipeline code locally. Update the cached pipeline with:

```bash
nextflow pull nf-core/pira
```

Use a release tag for production analyses:

```bash
nextflow run nf-core/pira -r <VERSION> ...
```

## Reproducibility

For reproducible analyses:

- Pin the pipeline version with `-r <VERSION>`;
- Use a versioned FASTA, GTF, and STAR index built from matching references;
- Keep the parameter file and custom configuration file with the analysis;
- Record the container or Conda profile used;
- Retain the `pipeline_info` outputs and MultiQC report.

The generated pipeline reports include execution metadata and software versions. `-resume` can be used to continue an interrupted run without recomputing completed processes.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a single hyphen. Pipeline parameters use two hyphens.

### `-profile`

Select an execution profile. See [Profiles](#profiles) above.

### `-resume`

Resume a previous run using cached process results:

```bash
nextflow run nf-core/pira -resume <run-name> ...
```

### `-c`

Load a custom Nextflow configuration file. Use this for resource tuning, infrastructure settings, or module arguments, not pipeline parameters.

## Custom configuration

### Resource requests

Process resources can be adjusted through a custom configuration file. Use process selectors or labels to customize CPUs, memory, time, executor settings, and retry behavior. See the nf-core documentation on [tuning workflow resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#tuning-workflow-resources).

### Custom containers

Containers can be overridden in a custom configuration when a local mirror or a different tool version is required. Keep the replacement container versioned and record the change with the analysis.

### Custom tool arguments

Tool-specific arguments can be supplied using the `ext.args` or `ext.args2` process configuration fields. For example:

```nextflow
process {
    withName: 'RMATS_POS' {
        ext.args = '--mil 30'
    }
}
```

Use module documentation and the tool manual to verify argument compatibility.

### nf-core/configs

Institutional profiles are loaded dynamically from [nf-core/configs](https://github.com/nf-core/configs). If your institution has a profile, provide it together with a supported container or Conda profile.

## Running in the background

Nextflow must remain active until the workflow completes. Use `-bg`, `screen`, `tmux`, or a scheduler job when running remotely:

```bash
nextflow run nf-core/pira -bg ...
```

## Nextflow memory requirements

If the Nextflow JVM requests too much memory, set `NXF_OPTS` before launching:

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
