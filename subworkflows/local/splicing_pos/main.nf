include { RMATS_POS   } from '../../../modules/local/rmats/post/main'

workflow SPLICING_POS {
    take:
    ch_input

    main:

    RMATS_POS(
        ch_input.map { it -> tuple( [id: it.condition], it.gtf ) },
        ch_input.map { it -> it.bam_1 },
        ch_input.map { it -> it.bam_2 },
        ch_input.map { it -> it.tmp_1 },
        ch_input.map { it -> it.tmp_2 },
        ch_input.map { it -> it.sequencing },
        ch_input.map { it -> it.length }
    )

    // versions

    ch_versions = channel.empty()
    RMATS_POS.out.versions.set { ch_versions }

    ch_multiqc = RMATS_POS.out.summary

    emit:
    multiqc  = ch_multiqc
    versions = ch_versions
}
