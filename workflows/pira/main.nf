/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


include { GENOME_BED                               } from '../../subworkflows/local/ID0/main'
include { GENOME_INDEX                             } from '../../subworkflows/local/ID0/main'
include { SAMPLES                                  } from '../../subworkflows/local/ID1/main'
include { CTRL1                                    } from '../../subworkflows/local/ID2/main'
include { ALIGNMENT                                } from '../../subworkflows/local/ID3/main'
include { ALIGNMENT_DENOVO                         } from '../../subworkflows/local/ID3/main'
include { ALIGNMENT_SPLICING_JUNCTION              } from '../../subworkflows/local/ID3/main'
include { CTRL2                                    } from '../../subworkflows/local/ID4/main'
include { CTRL3                                    } from '../../subworkflows/local/ID5/main'
include { ASSEMBLY_PRE                             } from '../../subworkflows/local/ID6/main'
include { ASSEMBLY_TRANSCRIPT                      } from '../../subworkflows/local/ID6/main'
include { ASSEMBLY_MERGE                           } from '../../subworkflows/local/ID6/main'
include { SPLICING_LENGTH                          } from '../../subworkflows/local/ID7/main'
include { SPLICING_PRE as SPLICING_PRE_WITH_NSS    } from '../../subworkflows/local/ID7/main'
include { SPLICING_PRE as SPLICING_PRE_WITHOUT_NSS } from '../../subworkflows/local/ID7/main'
include { SPLICING_POS as SPLICING_POS_WITH_NSS    } from '../../subworkflows/local/ID7/main'
include { SPLICING_POS as SPLICING_POS_WITHOUT_NSS } from '../../subworkflows/local/ID7/main'

include { softwareVersionsToYAML } from '../../subworkflows/nf-core/utils_nfcore_pipeline'

include { group_gtf                         } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_stats                       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_fastp_by_exp_cond_end       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_bam_by_cond                 } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_spl_by_alignment            } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { combine_by_cond                   } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { join_by_exp                       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { compute_pairs_by_cond             } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { reduce_strandedness_by_cond       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'

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

    //
    // SUBWORKFLOW: SAMPLES
    // ch_fastq = run, exp, cond, single_end, []fastq
    //

    if (params.with_fastq) {
        ch_fastq = ch_samples.map {
                row ->
                    if (row.single_end) {
                        row + [ fastq: [file(row.fastq_1)] ]
                    } else {
                        row + [ fastq: [file(row.fastq_1), file(row.fastq_2)] ]
                    }
            }
    } else {
        SAMPLES(ch_samples)
        ch_fastq = SAMPLES.out.data
        ch_versions = ch_versions.mix(SAMPLES.out.versions)
    }

    //
    // SUBWORKFLOW: CTRL1
    // ch_fastp = run, exp, cond, single_end, []fastp
    //

    CTRL1(ch_fastq)
    ch_fastp = CTRL1.out.data
    ch_versions = ch_versions.mix(CTRL1.out.versions)

    //
    // SUBWORKFLOW: ALIGNMENT
    // ch_bam = exp, cond, bam
    //

    ch_fastp_by_exp = group_fastp_by_exp_cond_end(
        ch_fastp
    )

    ALIGNMENT(
        ch_fastp_by_exp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index] },
    )

    ch_alignment = ALIGNMENT.out.data
    ch_versions = ch_versions.mix(ALIGNMENT.out.versions)

    if (params.with_twopass) {

        ch_spl = group_spl_by_alignment(
            ch_alignment
                .map { it -> [alignment: it.alignment, spl: it.spl] }
        )

        ALIGNMENT_SPLICING_JUNCTION(ch_spl)
        ch_spl = ALIGNMENT_SPLICING_JUNCTION.out.data
        ch_versions = ch_versions.mix(ALIGNMENT_SPLICING_JUNCTION.out.versions)

        ch_alignment_by_exp = join_by_exp(
            ch_fastp_by_exp,
            ch_alignment
        )

        ALIGNMENT_DENOVO(
            ch_alignment_by_exp
                .combine(ch_index)
                .map {row, index -> row + [index: index.index] }
                .combine(ch_spl)
                .map { row, spl -> row + [spl: spl.spl] }
        )

        ch_alignment = ALIGNMENT_DENOVO.out.data
        ch_versions = ch_versions.mix(ALIGNMENT_DENOVO.out.versions)

    }

    ch_bam = Channel.empty()
    ch_alignment
        .map { it -> [experiment: it.experiment, condition: it.condition, bam: it.bam] }
        .set { ch_bam }

    //
    // SUBWORKFLOW: CTRL2
    // ch_stats = exp, cond, stats
    //

    CTRL2(ch_bam)
    ch_stats = CTRL2.out.data

    //
    // SUBWORKFLOW: CTRL3
    // ch_strandedness = exp, cond, sequencing, strandedness, alias
    //

    CTRL3(
        ch_bam
            .combine(ch_bed)
            .map {row, bed -> row + [bed: bed.bed] },
    )
    ch_strandedness = CTRL3.out.data
    ch_versions = ch_versions.mix(CTRL3.out.versions)

    if (params.with_transcriptassembly) {

        //
        // SUBWORKFLOW: ASSEMBLY CLEAN
        // ch_gtf_clean = reference
        //

        ASSEMBLY_PRE(ch_gtf)
        ch_gtf_clean = ASSEMBLY_PRE.out.data
        ch_versions = ch_versions.mix(ASSEMBLY_PRE.out.versions)

        //
        // SUBWORKFLOW: ASSEMBLY TRANSCRIPT
        // ch_denovo = exp, cond, gtf
        //

        ch_assembly = join_by_exp(
            ch_bam,
            ch_strandedness
                .map { it -> [experiment: it.experiment, strandedness: it.strandedness]}
        )

        ASSEMBLY_TRANSCRIPT(
            ch_assembly
                .combine(ch_gtf_clean)
                .map {row, gtf -> row + [reference: gtf.reference] },
        )

        ch_versions = ch_versions.mix(ASSEMBLY_TRANSCRIPT.out.versions)

        //
        // SUBWORKFLOW: ASSEMBLY MERGE
        // ch_gtf_merged = gtf
        //

        ch_transcript = group_gtf(
            ASSEMBLY_TRANSCRIPT.out.data
                .map { it -> [gtf: it.gtf] }
        )

        ASSEMBLY_MERGE(
            ch_transcript
                .combine(ch_gtf_clean)
                .map {row, gtf -> row + [reference: gtf.reference] },
        )

        ch_gtf = ASSEMBLY_MERGE.out.data
        ch_versions = ch_versions.mix(ASSEMBLY_MERGE.out.versions)

    }

    //
    // SUBWORKFLOW: SPLICING
    //

    ch_stats = group_stats(ch_stats)

    SPLICING_LENGTH(
        ch_stats
    )

    ch_length = SPLICING_LENGTH.out.data
    ch_versions = ch_versions.mix(SPLICING_LENGTH.out.versions)

    // assumes alias, sequencing and strandedness are unique per condition
    ch_reduced_strandedness = reduce_strandedness_by_cond(
        ch_strandedness
    )

    ch_grouped_bam = group_bam_by_cond(
        ch_bam
            .map { it -> [condition: it.condition, bam: it.bam] }
    )

    ch_splicing_pre = combine_by_cond(
        ch_reduced_strandedness,
        ch_grouped_bam
    )

    if (params.with_novelss) {

        SPLICING_PRE_WITH_NSS(
            ch_splicing_pre
                .combine(
                    ch_length
                        .map { it -> [ length: it.length ] }
                )
                .map { row, length -> row + [length: length.length] }
                .combine(ch_gtf)
                .map { row, gtf -> row + [gtf: gtf.gtf] }
        )
        ch_splicing_prep = SPLICING_PRE_WITH_NSS.out.data
        ch_versions = ch_versions.mix(SPLICING_PRE_WITH_NSS.out.versions)

    } else {

        SPLICING_PRE_WITHOUT_NSS(
            ch_splicing_pre
                .combine(
                    ch_length
                        .map { it -> [ length: it.length ] }
                )
                .map { row, length -> row + [length: length.length] }
                .combine(ch_gtf)
                .map { row, gtf -> row + [gtf: gtf.gtf] }
        )
        ch_splicing_prep = SPLICING_PRE_WITHOUT_NSS.out.data
        ch_versions = ch_versions.mix(SPLICING_PRE_WITHOUT_NSS.out.versions)

    }

    ch_splicing_post = compute_pairs_by_cond(
        ch_splicing_prep
    )

    if (params.with_novelss) {

        SPLICING_POS_WITH_NSS(
            ch_splicing_post
                .combine(ch_gtf)
                .map { row, gtf -> row + [gtf: gtf.gtf] }
        )
        ch_versions = ch_versions.mix(SPLICING_POS_WITH_NSS.out.versions)

    } else {

        SPLICING_POS_WITHOUT_NSS(
            ch_splicing_post
                .combine(ch_gtf)
                .map { row, gtf -> row + [gtf: gtf.gtf] }
        )
        ch_versions = ch_versions.mix(SPLICING_POS_WITHOUT_NSS.out.versions)
    }

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
