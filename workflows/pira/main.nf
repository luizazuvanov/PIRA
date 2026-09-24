/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GENOME_BED                               } from '../../subworkflows/local/genome_bed/main'
include { GENOME_INDEX                             } from '../../subworkflows/local/genome_index/main'
include { SAMPLES                                  } from '../../subworkflows/local/rna_samples/main'
include { CTRL1                                    } from '../../subworkflows/local/rna_ctrl1/main'
include { ALIGNMENT                                } from '../../subworkflows/local/alignment/main'
include { ALIGNMENT_DENOVO                         } from '../../subworkflows/local/alignment_denovo/main'
include { ALIGNMENT_SPLICING_JUNCTION              } from '../../subworkflows/local/alignment_splicing_junction/main'
include { CTRL2                                    } from '../../subworkflows/local/quality_control_ctrl2/main'
include { CTRL3                                    } from '../../subworkflows/local/quality_control_ctrl3/main'
include { TRANSCRIPT_PRE                           } from '../../subworkflows/local/transcript_pre/main'
include { TRANSCRIPT_ASSEMBLY                      } from '../../subworkflows/local/transcript_assembly/main'
include { TRANSCRIPT_MERGE                         } from '../../subworkflows/local/transcript_merge/main'
include { SPLICING_LENGTH                          } from '../../subworkflows/local/splicing_length/main'
include { SPLICING_PRE as SPLICING_PRE_WITH_NSS    } from '../../subworkflows/local/splicing_pre/main'
include { SPLICING_PRE as SPLICING_PRE_WITHOUT_NSS } from '../../subworkflows/local/splicing_pre/main'
include { SPLICING_POS as SPLICING_POS_WITH_NSS    } from '../../subworkflows/local/splicing_pos/main'
include { SPLICING_POS as SPLICING_POS_WITHOUT_NSS } from '../../subworkflows/local/splicing_pos/main'

include { group_gtf                         } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_stats                       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_fastp_by_exp_cond_end       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_bam_by_cond                 } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { group_spl_by_alignment            } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { combine_by_cond                   } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { join_by_exp                       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { compute_pairs_by_cond             } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'
include { reduce_strandedness_by_cond       } from '../../subworkflows/local/utils_nextflow_pira_pipeline/main'

include { MULTIQC                } from '../../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../../subworkflows/local/utils_nfcore_pira_pipeline'

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
    multiqc_config
    multiqc_logo
    multiqc_methods_description

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

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
    ch_multiqc_files = ch_multiqc_files.mix(CTRL1.out.multiqc)

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
    ch_multiqc_files = ch_multiqc_files.mix(ALIGNMENT.out.multiqc)

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
        ch_multiqc_files = ch_multiqc_files.mix(ALIGNMENT_DENOVO.out.multiqc)

    }

    ch_bam = channel.empty()
    ch_alignment
        .map { it -> [experiment: it.experiment, condition: it.condition, bam: it.bam] }
        .set { ch_bam }

    //
    // SUBWORKFLOW: CTRL2
    // ch_stats = exp, cond, stats
    //

    CTRL2(ch_bam)
    ch_stats = CTRL2.out.data
    ch_versions = ch_versions.mix(CTRL2.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(CTRL2.out.multiqc)

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
    ch_multiqc_files = ch_multiqc_files.mix(CTRL3.out.multiqc)

    if (params.with_transcriptassembly) {

        //
        // SUBWORKFLOW: ASSEMBLY CLEAN
        // ch_gtf_clean = reference
        //

        TRANSCRIPT_PRE(ch_gtf)
        ch_gtf_clean = TRANSCRIPT_PRE.out.data
        ch_versions = ch_versions.mix(TRANSCRIPT_PRE.out.versions)

        //
        // SUBWORKFLOW: ASSEMBLY TRANSCRIPT
        // ch_denovo = exp, cond, gtf
        //

        ch_assembly = join_by_exp(
            ch_bam,
            ch_strandedness
                .map { it -> [experiment: it.experiment, strandedness: it.strandedness]}
        )

        TRANSCRIPT_ASSEMBLY(
            ch_assembly
                .combine(ch_gtf_clean)
                .map {row, gtf -> row + [reference: gtf.reference] },
        )

        ch_versions = ch_versions.mix(TRANSCRIPT_ASSEMBLY.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(TRANSCRIPT_ASSEMBLY.out.multiqc)

        //
        // SUBWORKFLOW: ASSEMBLY MERGE
        // ch_gtf_merged = gtf
        //

        ch_transcript = group_gtf(
            TRANSCRIPT_ASSEMBLY.out.data
                .map { it -> [gtf: it.gtf] }
        )

        TRANSCRIPT_MERGE(
            ch_transcript
                .combine(ch_gtf_clean)
                .map {row, gtf -> row + [reference: gtf.reference] },
        )

        ch_gtf = TRANSCRIPT_MERGE.out.data
        ch_versions = ch_versions.mix(TRANSCRIPT_MERGE.out.versions)

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
        ch_multiqc_files = ch_multiqc_files.mix(SPLICING_POS_WITH_NSS.out.multiqc)

    } else {

        SPLICING_POS_WITHOUT_NSS(
            ch_splicing_post
                .combine(ch_gtf)
                .map { row, gtf -> row + [gtf: gtf.gtf] }
        )
        ch_versions = ch_versions.mix(SPLICING_POS_WITHOUT_NSS.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(SPLICING_POS_WITHOUT_NSS.out.multiqc)
    }

    //
    // Versions
    //

    ch_collated_versions = softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pira_software_versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MULTIQC
    //

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)

    ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))

    ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))

    MULTIQC(
        ch_multiqc_files.flatten().collect(),
        multiqc_config
            ? file(multiqc_config, checkIfExists: true)
            : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
        [],
        multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
        [],
        []
    )

    emit:
    versions = ch_versions
    multiqc_report = MULTIQC.out.report.map { report -> [report] }.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
