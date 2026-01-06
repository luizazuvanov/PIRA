/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


include { GENOME_BED                            } from '../../subworkflows/local/ID0/main'
include { GENOME_INDEX                          } from '../../subworkflows/local/ID0/main'
include { SAMPLES                               } from '../../subworkflows/local/ID1/main'
include { CTRL1                                 } from '../../subworkflows/local/ID2/main'
include { ALIGNMENT_BASELINE                    } from '../../subworkflows/local/ID3/main'
include { ALIGNMENT_DENOVO                      } from '../../subworkflows/local/ID3/main'
include { CTRL2                                 } from '../../subworkflows/local/ID4/main'
include { CTRL3                                 } from '../../subworkflows/local/ID5/main'
include { ASSEMBLY_PRE                          } from '../../subworkflows/local/ID6/main'
include { ASSEMBLY_TRANSCRIPT                   } from '../../subworkflows/local/ID6/main'
include { ASSEMBLY_MERGE                        } from '../../subworkflows/local/ID6/main'
include { SPLICING_LENGTH                       } from '../../subworkflows/local/ID7/main'
include { SPLICING_PRE as SPLICING_PRE_BASELINE } from '../../subworkflows/local/ID7/main'
include { SPLICING_POS as SPLICING_POS_BASELINE } from '../../subworkflows/local/ID7/main'
include { SPLICING_PRE as SPLICING_PRE_DENOVO   } from '../../subworkflows/local/ID7/main'
include { SPLICING_POS as SPLICING_POS_DENOVO   } from '../../subworkflows/local/ID7/main'

include { softwareVersionsToYAML } from '../../subworkflows/nf-core/utils_nfcore_pipeline'

include { group_gtf_by_align                } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_stats_by_align              } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_fastp_by_exp_cond_end       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_bam_by_cond_keep_align      } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { combine_by_cond                   } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { join_by_exp                       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { compute_pairs_by_cond             } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { reduce_strandedness_by_cond_align } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIRA {

    take:
    ch_samples
    ch_fasta
    ch_gtf
    ch_index_optional

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: GENOME
    //

    GENOME_BED(ch_gtf)
    ch_bed = GENOME_BED.out.data
    ch_versions = ch_versions.mix(GENOME_BED.out.versions)

    def with_index = !(params.index == null || params.index.trim() == "")
    if (with_index) {
        ch_index = ch_index_optional
    } else {
        GENOME_INDEX(ch_fasta, ch_gtf)
        ch_index = GENOME_INDEX.out.data
        ch_versions = ch_versions.mix(GENOME_INDEX.out.versions)
    }

    if (params.step in ["download"]) {

        //
        // SUBWORKFLOW: SAMPLES
        // ch_fastq = run, exp, cond, single_end, []fastq
        //

        SAMPLES(ch_samples)
        ch_fastq = SAMPLES.out.data
        ch_versions = ch_versions.mix(SAMPLES.out.versions)

        ch_fastq = ch_fastq.map {row ->
            def single_end = (row.fastq.size() == 1)
            row + [ single_end: single_end ]
        }

    } else if (params.step in ["preprocessing"]) {

        //
        // Assume FASTQ files are provided in the samplesheet
        // ch_fastq = run, exp, cond, single_end, []fastq
        //

        ch_fastq = ch_samples.map { row ->
            def single_end = row.fastq_2 == null || row.fastq_2.trim() == ""
            def fastq = single_end ? file(row.fastq_1) : [file(row.fastq_1), file(row.fastq_2)]
            row + [ single_end: single_end, fastq: fastq ]
        }
    }

    if (params.step in ["download", "preprocessing"]) {

        //
        // SUBWORKFLOW: CTRL1
        // ch_fastp = run, exp, cond, single_end, []fastp
        //

        CTRL1(ch_fastq)
        ch_fastp = CTRL1.out.data
        ch_versions = ch_versions.mix(CTRL1.out.versions)

    } else if (params.step in ["alignment"]) {

        //
        // Assume FASTP processed FASTQ files are provided in the samplesheet
        // ch_fastp = run, exp, cond, single_end, []fastp
        //

        ch_fastp = ch_samples.map { row ->
            def single_end = row.fastp_2 == null || row.fastp_2.trim() == ""
            def fastp = single_end ? file(row.fastp_1) : [file(row.fastp_1), file(row.fastp_2)]
            row + [ single_end: single_end, fastp: fastp ]
        }
    }

    //
    // SUBWORKFLOW: ALIGNMENT
    // ch_bam = exp, alignment, cond, bam
    //

    ch_fastp_by_exp = group_fastp_by_exp_cond_end(
        ch_fastp
    )

    ALIGNMENT_BASELINE(
        ch_fastp_by_exp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index, alignment: "baseline"] },
    )

    ch_baseline = ALIGNMENT_BASELINE.out.data
    ch_versions = ch_versions.mix(ALIGNMENT_BASELINE.out.versions)

    ch_baseline_by_exp = join_by_exp(
        ch_fastp_by_exp,
        ch_baseline
    )

    ALIGNMENT_DENOVO(
        ch_baseline_by_exp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index, alignment: "denovo"] },
    )

    ch_denovo = ALIGNMENT_DENOVO.out.data
    ch_versions = ch_versions.mix(ALIGNMENT_DENOVO.out.versions)

    ch_bam = Channel.empty()
    ch_baseline
        .mix(ch_denovo)
        .map { it -> [experiment: it.experiment, alignment: it.alignment, condition: it.condition, bam: it.bam] }
        .set { ch_bam }

    //
    // SUBWORKFLOW: CTRL2
    // ch_stats = exp, alignment, cond, stats
    //

    CTRL2(ch_bam)
    ch_stats = CTRL2.out.data

    //
    // SUBWORKFLOW: CTRL3
    // ch_strandedness = exp, alignment, cond, sequencing, strandedness, alias
    //

    CTRL3(
        ch_bam
            .combine(ch_bed)
            .map {row, bed -> row + [bed: bed.bed] },
    )
    ch_strandedness = CTRL3.out.data
    ch_versions = ch_versions.mix(CTRL3.out.versions)

    //
    // SUBWORKFLOW: ASSEMBLY CLEAN
    // ch_gtf_clean = reference
    //

    ASSEMBLY_PRE(ch_gtf)
    ch_gtf_clean = ASSEMBLY_PRE.out.data
    ch_versions = ch_versions.mix(ASSEMBLY_PRE.out.versions)

    //
    // SUBWORKFLOW: ASSEMBLY_TRANSCRIPT
    // ch_denovo = exp, alignment, cond, gtf
    //

    ch_denovo = join_by_exp(
        ch_bam
            .filter {it -> it.alignment == "denovo"},
        ch_strandedness
            .filter {it -> it.alignment == "denovo"}
            .map { it -> [experiment: it.experiment, strandedness: it.strandedness]}
    )

    ASSEMBLY_TRANSCRIPT(
        ch_denovo
            .combine(ch_gtf_clean)
            .map {row, gtf -> row + [reference: gtf.reference] },
    )

    ch_versions = ch_versions.mix(ASSEMBLY_TRANSCRIPT.out.versions)

    //
    // SUBWORKFLOW: ASSEMBLY MERGE
    // ch_gtf_merged = alignment, gtf
    //

    ch_gtf_denovo = group_gtf_by_align(
        ASSEMBLY_TRANSCRIPT.out.data
    )

    ASSEMBLY_MERGE(
        ch_gtf_denovo
            .combine(ch_gtf_clean)
            .map {row, gtf -> row + [reference: gtf.reference] },
    )

    ch_gtf_denovo = ASSEMBLY_MERGE.out.data
    ch_versions = ch_versions.mix(ASSEMBLY_MERGE.out.versions)

    //
    // SUBWORKFLOW: SPLICING
    //

    ch_stats_by_align = group_stats_by_align(ch_stats)

    SPLICING_LENGTH(
        ch_stats_by_align
    )

    ch_length = SPLICING_LENGTH.out.data
    ch_versions = ch_versions.mix(SPLICING_LENGTH.out.versions)

    // BASELINE

    // assumes alias, sequencing and strandedness are unique per condition and alignment
    ch_baseline_strandedness = reduce_strandedness_by_cond_align(
        ch_strandedness
            .filter { it -> it.alignment == "baseline" }
    )

    ch_baseline_bam = group_bam_by_cond_keep_align(
        ch_bam
            .filter { it -> it.alignment == "baseline" }
            .map { it -> [condition: it.condition, alignment: it.alignment, bam: it.bam] }
    )

    ch_baseline_pre = combine_by_cond(
        ch_baseline_strandedness,
        ch_baseline_bam
    )

    SPLICING_PRE_BASELINE(
        ch_baseline_pre
            .combine(
                ch_length
                    .filter { it -> it.alignment == "baseline" }
                    .map { it -> [ length: it.length ] }
            )
            .map { row, length -> row + [length: length.length] }
            .combine(ch_gtf)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_baseline_rmats_prep = SPLICING_PRE_BASELINE.out.data
    ch_versions = ch_versions.mix(SPLICING_PRE_BASELINE.out.versions)

    ch_baseline_rmats_post = compute_pairs_by_cond(
        ch_baseline_rmats_prep
    )

    SPLICING_POS_BASELINE(
        ch_baseline_rmats_post
            .combine(ch_gtf)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_versions = ch_versions.mix(SPLICING_POS_BASELINE.out.versions)

    // DENOVO

    // assumes alias, sequencing and strandedness are unique per condition and alignment
    ch_denovo_strandedness = reduce_strandedness_by_cond_align(
        ch_strandedness
            .filter { it -> it.alignment == "denovo" }
    )

    ch_denovo_bam = group_bam_by_cond_keep_align(
        ch_bam
            .filter { it -> it.alignment == "denovo" }
            .map { it -> [condition: it.condition, alignment: it.alignment, bam: it.bam] }
    )

    ch_denovo_pre = combine_by_cond(
        ch_denovo_strandedness,
        ch_denovo_bam
    )

    SPLICING_PRE_DENOVO(
        ch_denovo_pre
            .combine(
                ch_length
                    .filter { it -> it.alignment == "denovo" }
                    .map { it -> [ length: it.length ] }
            )
            .map { row, length -> row + [length: length.length] }
            .combine(ch_gtf_denovo)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_denovo_rmats_prep = SPLICING_PRE_DENOVO.out.data
    ch_versions = ch_versions.mix(SPLICING_PRE_DENOVO.out.versions)

    ch_denovo_rmats_post = compute_pairs_by_cond(
        ch_denovo_rmats_prep
    )

    SPLICING_POS_DENOVO(
        ch_denovo_rmats_post
            .combine(ch_gtf_denovo)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_versions = ch_versions.mix(SPLICING_POS_DENOVO.out.versions)

    //
    // WRAP UP
    //

    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pira_software_versions.yml',
            sort: true,
            newLine: true
        )

    emit:
    multiqc_report = Channel.empty()
    versions = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
