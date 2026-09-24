# nf-core/pira: Output

## Introduction

This document describes the files and directories produced by nf-core/pira. All paths below are relative to the directory supplied with `--outdir`. The exact files depend on the input mode and optional analysis parameters. The `multiqc` and `pipeline_info` directories are produced for every successful run. Transcript assembly, de novo alignment, and novel splice-site outputs are produced only when the corresponding options are enabled.

## Output overview

A typical results directory contains:

```text
results/
├── bed/
├── fastp/
├── multiqc/
├── pipeline_info/
├── rmats/
├── rseqc/
├── samtools/
├── sj/
├── star/
├── strandedness/
└── stringtie/
```

## Reference preprocessing

### `bed/`

BED-format annotation generated from the input GTF using UCSC Kent utilities. The BED annotation is used by RSeQC for strandedness inference.

### `star/`

STAR alignment and, when no compatible `--index` is supplied, the generated STAR genome index. Alignment results are grouped by alignment mode, for example:

- `star/baseline/`: primary STAR alignment results;
- `star/denovo/`: second-pass alignment results when `--with_twopass` is enabled.

Depending on the configuration, sample directories can contain:

- `*.Aligned.sortedByCoord.out.bam`: coordinate-sorted alignment;
- `*.Log.final.out`: STAR alignment summary used by MultiQC;
- `*.Log.out` and `*.Log.progress.out`: STAR execution logs;
- `*.SJ.out.tab`: splice-junction output;
- `*.ReadsPerGene.out.tab`: STAR gene-count output when enabled;
- `*.unmapped_*.fastq.gz`: unmapped reads;
- additional STAR alignment files such as transcriptome BAMs, SAM files, wiggle files, and bedGraph files.

When an existing STAR index is supplied with `--index`, the index is used directly and is not regenerated.

## RNA-seq preprocessing

### `fastp/`

FASTP output is organized by sequencing run. Depending on the input and module options, each run can include:

- `*.fastp.json`: machine-readable FASTP report consumed by MultiQC;
- `*.fastp.html`: standalone FASTP report;
- `*.fastp.log`: FASTP log;
- `*.fastp.fastq.gz`: trimmed FASTQ files.

When `--with_fastq` is omitted, the intermediate SRA download and FASTQ conversion files are used by the workflow and are not intended as the primary report outputs.

## Quality control

### `samtools/`

SAMtools outputs for aligned BAM files, including:

- `*.stats`: alignment statistics consumed by MultiQC;
- `*.bai`, `*.csi`, or `*.crai`: BAM/CRAM indexes, depending on the input and configuration.

### `rseqc/`

RSeQC `infer_experiment.py` reports for each experiment. These text reports are passed to MultiQC and support library-strandedness assessment.

### `strandedness/`

Pipeline-derived CSV files containing the inferred sequencing layout, strandedness, and alias for each experiment. These files are used to configure downstream transcript assembly and rMATS analysis.

### `sj/`

Filtered STAR splice-junction tables. These are used by the optional two-pass alignment workflow to provide supported junctions to the second STAR alignment.

## Transcript assembly

### `stringtie/`

Generated when `--with_transcriptassembly` is enabled. Outputs include:

- per-experiment `*.transcripts.gtf` files from StringTie transcript assembly;
- per-experiment `*.gene.abundance.txt` files containing coverage, FPKM, and TPM values;
- `stringtie.merged.gtf`, the merged transcript annotation used for downstream splicing analysis.

The StringTie abundance tables are pipeline outputs; the primary MultiQC report currently uses the formats supported by its native modules.

## Alternative splicing

### `rmats/`

rMATS preparation and post-processing outputs. Depending on the selected mode, this directory can contain:

- `prep/`: rMATS preparation intermediates;
- `post/`: event-level alternative-splicing results;
- `*.MATS.JC.txt`: results based on splice-junction counts;
- `*.MATS.JCEC.txt`: results based on junction and exon-body counts;
- `fromGTF.*.txt`: detected alternative-splicing event definitions;
- `JC.raw.input.*.txt` and `JCEC.raw.input.*.txt`: raw event-count inputs;
- `summary.txt`: summary of total and significant events across event types.

The `rMATS` outputs include skipped exon (SE), alternative 3' splice site (A3SS), alternative 5' splice site (A5SS), mutually exclusive exon (MXE), and retained intron (RI) event types.

## MultiQC

### `multiqc/`

MultiQC aggregates supported reports from the workflow into one report:

- `multiqc_report.html`: standalone interactive HTML report;
- `multiqc_data/`: parsed MultiQC data and report metadata;
- `multiqc_plots/`: generated plot assets.

The report can include FASTP, STAR, SAMtools, and RSeQC sections, as well as workflow parameters, methods text, and software versions. StringTie abundance tables and rMATS summaries remain available as pipeline outputs but are not currently native MultiQC inputs.

## Pipeline information

### `pipeline_info/`

Execution and provenance files generated by Nextflow and the nf-core template include:

- `execution_report_*.html`: execution report;
- `execution_timeline_*.html`: process timeline;
- `execution_trace_*.txt`: process trace data;
- `pipeline_dag_*.html`: workflow DAG;
- `params_*.json`: parameters used for the run;
- `nf_core_pira_software_versions.yml`: collated software versions used by the pipeline.

These files are useful for troubleshooting, auditing, and reproducing a run.

## Reading the results

Start with the MultiQC report for a run-level overview of preprocessing, alignment, alignment statistics, strandedness, software versions, and workflow metadata. Use the rMATS event tables and `summary.txt` for alternative-splicing results, and the STAR, SAMtools, RSeQC, and StringTie directories for detailed tool-specific outputs.
