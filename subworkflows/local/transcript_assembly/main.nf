include { STRINGTIE_STRINGTIE } from '../../../modules/local/stringtie/stringtie/main'

workflow TRANSCRIPT_ASSEMBLY {

    take:
    ch_input

    main:

    STRINGTIE_STRINGTIE(
        ch_input
        .map { it -> tuple(
            [id: it.experiment, condition: it.condition, strandedness: it.strandedness],
            it.bam
        ) },
        ch_input
        .map { it -> it.reference }
    )

    // clean

    ch_out = channel.empty()
    STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { it -> [experiment: it[0].id, condition: it[0].condition, gtf: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    STRINGTIE_STRINGTIE.out.versions.set { ch_versions }

    ch_multiqc = STRINGTIE_STRINGTIE.out.abundance
        .map { _meta, report -> report }

    emit:
    data     = ch_out
    multiqc  = ch_multiqc
    versions = ch_versions
}
