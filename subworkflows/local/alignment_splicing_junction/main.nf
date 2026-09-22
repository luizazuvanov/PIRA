include { SJ_FILTER } from '../../../modules/local/sj/filter/main'

workflow ALIGNMENT_SPLICING_JUNCTION {

    take:
    ch_input

    main:

    SJ_FILTER(
        ch_input.map { it -> tuple([id: it.alignment], it.spl) }
    )

    // clean

    ch_out = channel.empty()
    SJ_FILTER.out.spl_junc_tab
        .map { it -> [alignment: it[0].id, spl: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    SJ_FILTER.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
