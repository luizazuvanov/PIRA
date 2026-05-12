# nf-core/pira: Output

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/pira/output](https://nf-co.re/pira/output)

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report generated from the full-sized test dataset for the pipeline using a command similar to the one below:

```bash
nextflow run nf-core/pira -profile test_full,docker --outdir results
```

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory specified with `--outdir`.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Reference genome preparation](#reference-genome-preparation)
  - [BED file generation](#bed-file-generation) — Convert GTF annotation to BED12 format for RSeQC.
  - [STAR genome index](#star-genome-index) — Build a STAR splice-aware genome index.
- [Sample retrieval](#sample-retrieval) _(optional)_
  - [SRA Toolkit](#sra-toolkit) — Download raw reads from NCBI SRA.
- [Quality control and trimming](#quality-control-and-trimming)
  - [fastp](#fastp) — Adapter trimming and per-run quality-control reports.
- [Alignment](#alignment)
  - [STAR — baseline pass](#star--baseline-pass) — Initial spliced alignment.
  - [Splice junction filtering](#splice-junction-filtering) — Filter novel junctions for the two-pass step.
  - [STAR — two-pass (de novo) alignment](#star--two-pass-de-novo-alignment) — Re-alignment using discovered junctions.
- [Alignment post-processing](#alignment-post-processing)
  - [SAMtools](#samtools) — Sort, index, and generate alignment statistics.
- [Alignment quality control](#alignment-quality-control)
  - [RSeQC](#rseqc) — Junction annotation, saturation, read distribution, and strandedness inference.
- [Transcript assembly](#transcript-assembly) _(optional)_
  - [StringTie2](#stringtie2) — Per-experiment transcript assembly and multi-sample merge.
- [Alternative splicing analysis](#alternative-splicing-analysis)
  - [rMATS](#rmats) — Event-based differential splicing detection.
- [Pipeline information](#pipeline-information) — Nextflow execution reports and software versions.

---

## Reference genome preparation

### BED file generation

<details markdown="1">
<summary>Output files</summary>

- `bed/`
  - `*.bed`: BED12 file derived from the input GTF annotation. Used by RSeQC tools.

</details>

The GTF annotation is converted to BED12 format using UCSC command-line utilities (`gtfToGenePred` + `genePredToBed`). This file is required by several RSeQC modules to relate read alignments to known transcript structures.

### STAR genome index

<details markdown="1">
<summary>Output files</summary>

- `star/`
  - `index/`: Directory containing the STAR genome index (only generated when `--index` is not provided).

</details>

[STAR](https://github.com/alexdobin/STAR) builds a genome index from the supplied FASTA and GTF files. This step is skipped when a pre-built index directory is supplied via `--index`. The index must be built with the same STAR version used for alignment. For a human-sized genome (~3 Gb) expect approximately 40 GB of RAM.

---

## Sample retrieval

### SRA Toolkit

<details markdown="1">
<summary>Output files</summary>

- `sratools/`
  - `<run_id>/`: Per-run directory containing the downloaded FASTQ file(s) in gzipped format.

</details>

When `--with_fastq` is **not** set, the pipeline uses the `run` column of the samplesheet as an NCBI SRA Run accession ID and downloads the corresponding FASTQ files using [SRA Toolkit](https://github.com/ncbi/sra-tools) (`prefetch` + `fasterq-dump`). For paired-end experiments, two FASTQ files are produced per run. This step is skipped entirely when `--with_fastq` is set.

---

## Quality control and trimming

### fastp

<details markdown="1">
<summary>Output files</summary>

- `fastp/<run_id>/`
  - `*.fastp.fastq.gz`: Adapter-trimmed and quality-filtered FASTQ file(s). These files are used as input for STAR alignment.
  - `*.fastp.json`: Machine-readable QC metrics in JSON format (ingested by MultiQC).
  - `*.fastp.html`: Interactive HTML QC report with per-base quality, GC content, duplication rate, and adapter content.
  - `*.fastp.log`: Plain-text log file from fastp.

</details>

[fastp](https://github.com/OpenGene/fastp) performs adapter detection and trimming, quality filtering, and per-run quality-control reporting in a single pass. For paired-end data, adapter sequences are auto-detected from read overlap. The trimmed FASTQ files are passed directly to STAR for alignment.

---

## Alignment

### STAR — baseline pass

<details markdown="1">
<summary>Output files</summary>

- `star/baseline/<experiment_id>/`
  - `*.Aligned.sortedByCoord.out.bam`: Coordinate-sorted BAM file of aligned reads.
  - `*.SJ.out.tab`: Splice junction table discovered during the baseline alignment.
  - `*.Log.final.out`: Alignment summary with mapping rates (uniquely mapped, multi-mapped, unmapped).
  - `*.Log.out`, `*.Log.progress.out`: Verbose STAR log files.
  - `*.ReadsPerGene.out.tab`: Gene-level read counts in stranded and unstranded formats.

</details>

[STAR](https://github.com/alexdobin/STAR) (Spliced Transcripts Alignment to a Reference) maps trimmed reads to the reference genome using a splice-aware algorithm. Multiple runs belonging to the same `experiment` are merged before alignment. The baseline pass discovers novel splice junctions stored in `*.SJ.out.tab`; these junctions feed into the two-pass step when `--with_twopass` is set (default).

### Splice junction filtering

<details markdown="1">
<summary>Output files</summary>

- `sj/<experiment_id>/`
  - `*.filtered.SJ.out.tab`: Filtered splice junction table used as input to the two-pass STAR alignment.

</details>

A custom filtering step removes low-confidence and artefactual junctions from the baseline STAR splice junction table before they are used in the de novo alignment step.

### STAR — two-pass (de novo) alignment

<details markdown="1">
<summary>Output files</summary>

- `star/denovo/<experiment_id>/`
  - `*.Aligned.sortedByCoord.out.bam`: Coordinate-sorted BAM file from the two-pass alignment. **This is the BAM file used by all downstream steps.**
  - `*.Log.final.out`: Alignment summary for the two-pass alignment.
  - `*.Log.out`, `*.Log.progress.out`: Verbose STAR log files.
  - `*.ReadsPerGene.out.tab`: Gene-level read counts from the two-pass alignment.

</details>

The two-pass alignment re-runs STAR using the filtered splice junctions discovered in the baseline pass (`--sjdbFileChrStartEnd`). This improves sensitivity for novel and lowly-expressed splice junctions. The two-pass step is enabled by default (`--with_twopass true`) and can be disabled with `--with_twopass false`.

## Alignment post-processing

### SAMtools

<details markdown="1">
<summary>Output files</summary>

- `samtools/<experiment_id>/`
  - `*.bai`: BAM index file (required for random-access by downstream tools).
  - `*.stats`: Comprehensive alignment statistics produced by `samtools stats`.

</details>

[SAMtools](http://www.htslib.org/) indexes the coordinate-sorted BAM files and generates per-experiment alignment statistics. The `stats` file contains read counts, mapping quality distributions, insert-size metrics, and error rates. These statistics are also used downstream by rMATS to determine read length.

---

## Alignment quality control

### RSeQC

<details markdown="1">
<summary>Output files</summary>

- `rseqc/<experiment_id>/`
  - `*.infer_experiment.txt`: Output of `infer_experiment.py`. Reports the fraction of reads consistent with forward, reverse, and unstranded library preparations. The inferred strandedness is propagated to StringTie2 and rMATS.
  - `*.junction_annotation.{txt,bed,xls}`: Output of `junction_annotation.py`. Annotates splice junctions as known, partial novel, or complete novel.
  - `*.junction_annotation_plot.{r,pdf}`: R script and PDF plot of junction categories.
  - `*.junction_saturation.{r,pdf}`: R script and PDF plot from `junction_saturation.py`, showing the fraction of known junctions detected as a function of sequencing depth.
  - `*.read_distribution.txt`: Output of `read_distribution.py`. Breaks down the proportion of reads mapping to CDS exons, UTRs, introns, intergenic regions, and other genomic features.

</details>

[RSeQC](http://rseqc.sourceforge.net/) provides a suite of quality-control modules that assess the quality of RNA-seq alignments.

- **`infer_experiment.py`** determines library strand specificity by comparing read orientations to the annotation BED file. The inferred strandedness (`fr-firststrand`, `fr-secondstrand`, or `unstranded`) is propagated automatically to StringTie2 and rMATS to ensure correct strand-aware processing.
- **`junction_annotation.py`** classifies all splice junctions detected in the BAM file as known (present in the GTF), partial novel (one splice site is known), or complete novel.
- **`junction_saturation.py`** assesses whether sequencing depth is sufficient to detect all splice junctions in the library by subsampling the BAM file.
- **`read_distribution.py`** quantifies what proportion of reads falls in each genomic feature category.

---

## Transcript assembly

> This section applies only when `--with_transcriptassembly true` (default).

### StringTie2

<details markdown="1">
<summary>Output files</summary>

- `stringtie/<experiment_id>/`
  - `*.transcripts.gtf`: Per-experiment GTF file with assembled transcripts, guided by the reference annotation.
  - `*.abundance.txt`: Transcript-level abundance estimates (FPKM, TPM, coverage).
  - `*.ballgown/`: Ballgown input tables for optional downstream differential expression analysis.
- `stringtie/`
  - `merged.gtf`: Consensus GTF produced by merging all per-experiment assemblies. **This GTF replaces the input reference annotation for rMATS.**

</details>

[StringTie2](https://ccb.jhu.edu/software/stringtie/) assembles transcripts from each experiment's BAM file guided by the reference GTF. The inferred strand specificity from RSeQC is passed to StringTie2 (`--rf` or `--fr` flag). All per-experiment GTFs are then merged with `stringtie --merge` to produce a single consensus annotation that includes both reference and novel transcripts. This consensus GTF is used by rMATS, which can improve the detection of alternative splicing events involving novel exons or splice sites.

When `--with_transcriptassembly false` is set, the original input GTF is passed directly to rMATS.

---

## Alternative splicing analysis

### rMATS

<details markdown="1">
<summary>Output files</summary>

- `rmats/<condition_pair>/`
  - `SE.MATS.JC.txt`, `SE.MATS.JCEC.txt`: Skipped Exon (SE) events with junction-count (JC) and junction-count + exon-count (JCEC) statistics.
  - `A5SS.MATS.JC.txt`, `A5SS.MATS.JCEC.txt`: Alternative 5′ Splice Site (A5SS) events.
  - `A3SS.MATS.JC.txt`, `A3SS.MATS.JCEC.txt`: Alternative 3′ Splice Site (A3SS) events.
  - `MXE.MATS.JC.txt`, `MXE.MATS.JCEC.txt`: Mutually Exclusive Exon (MXE) events.
  - `RI.MATS.JC.txt`, `RI.MATS.JCEC.txt`: Retained Intron (RI) events.
  - `fromGTF.<event_type>.txt`: All events of each type annotated from the GTF.
  - `fromGTF.novelJunction.<event_type>.txt`: Novel-junction events not in the reference GTF.
  - `fromGTF.novelSpliceSite.<event_type>.txt`: Novel-splice-site events (present only when `--with_novelss true`).
  - `JC.raw.input.<event_type>.txt`, `JCEC.raw.input.<event_type>.txt`: Raw count matrices used as input to the statistical model.
  - `individualCounts.<event_type>.txt`: Per-sample inclusion and skipping counts.
  - `summary.txt`: Summary statistics for all event types.

</details>

[rMATS-turbo](https://github.com/Xinglab/rmats-turbo) (v4.3.0) is used to detect and quantify differential alternative splicing events between pairs of conditions. The pipeline runs rMATS in a two-step mode:

1. **Prep step (`--task prep`)** — processes each condition's BAM files independently to compute per-condition splicing statistics. The read length is determined automatically from the SAMtools stats output by computing a weighted average across all experiments within each condition. When runs within the same condition have variable read lengths (e.g., from different sequencing runs), the pipeline uses the `--variable-read-length` flag for rMATS, which relaxes the fixed-length assumption and handles length heterogeneity gracefully.
2. **Post step (`--task post`)** — combines the prep-step outputs from both conditions to perform the pairwise statistical test and generate the final output tables.

All pairwise condition comparisons are performed automatically: for _n_ conditions, _n(n−1)/2_ comparisons are run.

**Output columns** (`.MATS.JC.txt` / `.MATS.JCEC.txt`):

| Column            | Description                                                                                  |
| ----------------- | -------------------------------------------------------------------------------------------- |
| `ID`              | Unique event identifier.                                                                     |
| `GeneID`          | Ensembl gene identifier.                                                                     |
| `geneSymbol`      | Gene name.                                                                                   |
| `chr`, `strand`   | Genomic coordinates and strand of the event.                                                 |
| `IJC_SAMPLE_1/2`  | Inclusion junction counts for each replicate in condition 1 / 2.                             |
| `SJC_SAMPLE_1/2`  | Skipping junction counts for each replicate in condition 1 / 2.                              |
| `IncLevel1/2`     | Percent Spliced In (PSI / Ψ) values per replicate.                                           |
| `IncLevelDifference` | Mean PSI difference (condition 1 − condition 2).                                          |
| `PValue`          | Likelihood-ratio test p-value.                                                               |
| `FDR`             | Benjamini–Hochberg false discovery rate.                                                     |

> [!NOTE]
> By default, rMATS is run with `--novelSS --mil 30 --variable-read-length` (controlled by `--with_novelss`). The `--novelSS` flag enables detection of splicing events at novel splice sites not annotated in the reference GTF. To disable novel splice-site detection (e.g. for a more conservative analysis), set `--with_novelss false`.

---

## Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - `execution_report_<timestamp>.html`: Nextflow HTML execution report — per-task resource usage, timeline, and status.
  - `execution_timeline_<timestamp>.html`: Gantt-chart view of task start times and durations.
  - `execution_trace_<timestamp>.txt`: Tab-separated trace file with per-task CPU, memory, I/O, and wall-time metrics.
  - `pipeline_dag_<timestamp>.{dot,svg}`: Directed acyclic graph (DAG) of the pipeline execution.
  - `nf_core_pira_software_versions.yml`: YAML file listing the exact version of every software tool used in the run.
  - `params.json`: JSON file recording all parameters used for the pipeline run.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides built-in functionality for generating execution reports. These files allow you to troubleshoot run failures, audit resource usage, and ensure full reproducibility by recording the exact parameters and software versions used.

