# nf-core/pira Pipeline Proposal

## Pipeline title/name

`pira`

## Keywords

RNA-seq, alternative splicing, transcriptomics, RNA isoforms, de novo splice-site detection, rMATS, STAR, C. elegans

## What is it about?

PIRA is a specialized end-to-end RNA-seq workflow for discovering and quantifying alternative splicing events, with particular emphasis on events absent from the supplied reference annotation. It accepts either user-provided FASTQ files or public SRA run accessions, together with a reference FASTA and GTF annotation.

Unlike a general RNA-seq pipeline whose primary outputs are alignments and expression matrices, PIRA is organized around layered alternative-splicing discovery. It combines alignment evidence, reconstructed transcript models, and event-level splice-site detection before producing rMATS-turbo results. The three discovery layers are STAR two-pass alignment, StringTie transcript assembly, and rMATS novel splice-site detection.

## Schematic diagram

Upload the rendered `assets/metro_map.svg` file to the proposal issue.

The source diagram is [assets/metro_map.mmd](metro_map.mmd).

## What would a minimal first release include?

The minimum useful release would be a focused alternative-splicing workflow rather than a broad RNA-seq quantification framework:

- Samplesheet input with SRA accessions or local FASTQ files;
- Reference FASTA and GTF inputs;
- Optional STAR index input, with index generation when omitted;
- FASTQ preprocessing with fastp;
- STAR alignment as the evidence-generation stage;
- SAMtools BAM statistics and indexing;
- RSeQC strandedness inference;
- rMATS-turbo preparation and post-processing for event-level splice quantification;
- MultiQC reporting;
- Docker/Singularity-compatible execution;
- Basic nf-test coverage and nf-core standardized parameters;
- Stub-run support.

The defining feature of the first release would be the coordinated de novo strategy: STAR two-pass alignment, StringTie transcript assembly, and rMATS novel splice-site detection. These are complementary discovery layers designed to improve detection of unannotated junctions, isoforms, and splicing events.

## nf-core requirements

The proposal is intended to follow nf-core requirements:

- [x] Built with Nextflow DSL2;
- [ ] Pass nf-core lint and CI tests;
- [ ] Community-owned and developed within the nf-core organization;
- [x] Open source under the MIT license with credits and acknowledgments;
- [x] Uses a descriptive, lowercase pipeline name;
- [ ] Uses the nf-core template and predominantly official nf-core modules;
- [x] Focuses on a specific analysis type with appropriate scope;
- [ ] Has complete, maintained documentation;
- [x] Uses versioned Docker/Singularity-compatible software containers.

The remaining unchecked items are active preparation work for the nf-core review: enabling CI/CD, finalizing testing profiles, refactoring documentation, and configuring repository branches and protection rules.

## Why do we need a new pipeline?

PIRA addresses a gap between general RNA-seq processing and specialized alternative-splicing analysis. Generic RNA-seq workflows typically optimize read QC, alignment, transcript or gene quantification, and broad reporting. They do not make discovery of unannotated splicing events the central analytical objective or coordinate multiple discovery layers for that purpose.

This distinction is particularly important for organisms such as _C. elegans_, where transcript annotations remain incomplete and tissue-, developmental-stage-, and disease-specific isoforms may be absent from reference annotations. PIRA combines three complementary discovery layers:

1. STAR two-pass alignment to improve support for unannotated splice junctions;
2. StringTie transcript assembly to reconstruct novel isoforms;
3. rMATS-turbo novel splice-site detection to identify additional unannotated splicing events.

Preliminary simulation results from Luíza Zuvanov's in-progress PhD thesis (pipeline author) indicate that activating all three layers improves novel-event detection, with an overall F1-score of approximately 0.68 and a TASS-specific precision, recall, and F1-score of approximately 81%, 71%, and 75%, respectively. These results are currently unpublished and will be documented and validated further as the work progresses.

The novelty is analytical rather than merely infrastructural: PIRA treats incomplete annotation as an explicit design assumption and evaluates the effect of progressively enabling discovery layers. It provides a reproducible, scalable, and portable implementation through Nextflow and nf-core conventions while retaining a focused biological objective: finding and quantifying alternative splicing that a reference-only workflow could miss.

## Who would be interested?

- Researchers studying alternative splicing, isoform regulation, and splice-site choice;
- RNA-seq analysts working with incomplete or evolving genome annotations;
- Researchers studying _C. elegans_ development, tissues, or disease models;
- Transcriptomics and RNA biology groups that need event-level rather than only gene-level results;
- Groups comparing alternative-splicing landscapes across multiple datasets;
- Users requiring reproducible execution on HPC, cloud, or local container platforms.

## What has been done so far?

A functional Nextflow DSL2 implementation exists and is currently being prepared for nf-core review. The implementation is positioned as a focused alternative-splicing workflow, with generic RNA-seq preprocessing and alignment serving as supporting stages rather than the primary scientific output.

The current prototype includes:

- nf-core pipeline structure and parameter schema;
- STAR, SAMtools, RSeQC, SRA Toolkit, MultiQC, and StringTie components;
- Local modules for fastp, UCSC BED conversion, splice-junction filtering, strandedness parsing, StringTie assembly, read-length detection, and rMATS prep/post-processing;
- Optional STAR two-pass alignment;
- Optional StringTie transcript assembly;
- Optional rMATS novel splice-site detection;
- MultiQC integration for fastp, STAR, SAMtools, and RSeQC reports;
- Unit tests for channel-manipulation utilities;
- Stub-run support;
- A pipeline metro map and initial documentation.

Remaining preparation work includes enabling nf-core CI/CD, refining testing profiles, completing documentation, and configuring repository branches and protection rules.

## URL to existing work

https://github.com/nf-core/pira

## Are there any similar existing nf-core pipelines?

`rnaseq`

`nf-core/rnaseq` is the closest related pipeline because it performs RNA-seq preprocessing, alignment, transcript assembly, quality control, and MultiQC reporting. PIRA has a narrower focus on alternative splicing discovery and quantification, especially in the presence of incomplete annotations.
