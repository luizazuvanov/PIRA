# nf-core/pira Pipeline Proposal

## Pipeline title/name

`pira`

## Keywords

RNA-seq, alternative splicing, transcriptomics, RNA isoforms, de novo splice-site detection, rMATS, STAR, C. elegans

## What is it about?

PIRA is an end-to-end RNA-seq workflow for identifying and quantifying alternative splicing events. It accepts either user-provided FASTQ files or public SRA run accessions, together with a reference FASTA and GTF annotation.

The pipeline performs read preprocessing, STAR alignment, BAM quality control, strandedness inference, and alternative splicing quantification with rMATS-turbo. It includes three optional de novo discovery layers: STAR two-pass alignment, StringTie transcript assembly, and rMATS novel splice-site detection.

## Schematic diagram

Upload the rendered `assets/metro_map.svg` file to the proposal issue.

The source diagram is [assets/metro_map.mmd](metro_map.mmd).

## What would a minimal first release include?

- Samplesheet input with SRA accessions or local FASTQ files;
- Reference FASTA and GTF inputs;
- Optional STAR index input, with index generation when omitted;
- FASTQ preprocessing with fastp;
- STAR alignment;
- SAMtools BAM statistics and indexing;
- RSeQC strandedness inference;
- rMATS-turbo preparation and post-processing;
- MultiQC reporting;
- Docker/Singularity-compatible execution;
- Basic nf-test coverage and nf-core standardized parameters;
- Stub-run support.

The STAR two-pass, StringTie transcript assembly, and rMATS novel splice-site layers are already implemented as optional components and could be included in the first release or finalized as early follow-up features.

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

Existing RNA-seq pipelines provide alignment, quantification, or general quality control, but do not directly target systematic discovery and quantification of alternative splicing events with multiple coordinated de novo strategies.

This is particularly important for organisms such as _C. elegans_, where transcript annotations remain incomplete and tissue-, developmental-stage-, and disease-specific isoforms may be absent from reference annotations. PIRA combines three complementary discovery layers:

1. STAR two-pass alignment to improve support for unannotated splice junctions;
2. StringTie transcript assembly to reconstruct novel isoforms;
3. rMATS-turbo novel splice-site detection to identify additional unannotated splicing events.

Simulation results indicate that activating all three layers improves novel-event detection, with an overall F1-score of approximately 0.68 and a TASS-specific precision, recall, and F1-score of approximately 81%, 71%, and 75%, respectively.

PIRA also provides a reproducible, scalable, and portable implementation through Nextflow and nf-core conventions.

## Who would be interested?

- Researchers studying alternative splicing and isoform regulation;
- RNA-seq analysts working with incomplete or evolving genome annotations;
- Researchers studying _C. elegans_ development, tissues, or disease models;
- Transcriptomics and RNA biology groups;
- Groups analysing multiple RNA-seq datasets consistently;
- Users requiring reproducible execution on HPC, cloud, or local container platforms.

## What has been done so far?

A functional Nextflow DSL2 implementation exists and is currently being prepared for nf-core review.

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
