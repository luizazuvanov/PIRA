include { STRINGTIE_CLEAN     } from '../../../modules/local/stringtie/clean/main'

workflow TRANSCRIPT_PRE {

    take:
    ch_input

    main:

    STRINGTIE_CLEAN(
        ch_input.map { it -> tuple([id: "gtf"], it.gtf) }
    )

    ch_out = channel.empty()
    STRINGTIE_CLEAN.out.gtf_clean
        .map { it -> [reference: it] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    STRINGTIE_CLEAN.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
