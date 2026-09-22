include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'

workflow TRANSCRIPT_MERGE {

    take:
    ch_input

    main:

    STRINGTIE_MERGE(
        ch_input.map { it -> it.gtf },
        ch_input.map { it -> it.reference }
    )

    // clean

    ch_out = channel.empty()
    ch_input
        .combine(STRINGTIE_MERGE.out.gtf)
        .map { _row, gtf -> [gtf: gtf] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    STRINGTIE_MERGE.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
