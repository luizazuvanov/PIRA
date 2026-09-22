include { RMATS_LENGTH } from '../../../modules/local/rmats/length/main'

workflow SPLICING_LENGTH {
    take:
    ch_input

    main:

    RMATS_LENGTH(
        ch_input.map { _it -> [id: "length"] },
        ch_input.map { it -> it.stats }
    )

    ch_out = channel.empty()
    RMATS_LENGTH.out.stats
        .map { it -> [length: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    RMATS_LENGTH.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
