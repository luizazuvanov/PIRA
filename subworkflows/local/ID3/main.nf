include { SJ_FILTER } from '../../../modules/local/sj/filter/main'
include { STAR_ALIGN } from '../../../modules/nf-core/star/align/main'

workflow ALIGNMENT {

    take:
    ch_input

    main:

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, alignment: 'baseline', condition: it.condition, single_end: it.single_end], it.fastp) },
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        [[], []],
        true,
        "",
        ""
    )

    // clean

    ch_out_bam = Channel.empty()
    STAR_ALIGN.out.bam_sorted_aligned
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, bam: it[1]] }
        .set { ch_out_bam }

    ch_out_spl = Channel.empty()
    STAR_ALIGN.out.spl_junc_tab
        .map { it -> [experiment: it[0].id, condition: it[0].condition, spl: it[1]] }
        .set { ch_out_spl }

    // join

    ch_out = ch_out_bam
        .map { it -> tuple(it.experiment, it) }
        .join(
            ch_out_spl
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key

    // versions

    ch_versions = Channel.empty()
    STAR_ALIGN.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}

workflow ALIGNMENT_SPLICING_JUNCTION {

    take:
    ch_input

    main:

    SJ_FILTER(
        ch_input.map { it -> tuple([id: it.alignment], it.spl) }
    )

    // clean

    ch_out = Channel.empty()
    SJ_FILTER.out.spl_junc_tab
        .map { it -> [alignment: it[0].id, spl: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    SJ_FILTER.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions

}

workflow ALIGNMENT_DENOVO {

    take:
    ch_input

    main:

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, alignment: 'denovo', condition: it.condition, single_end: it.single_end, spl: it.spl], it.fastp) },
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        [[], []],
        true,
        "",
        ""
    )

    // clean

    ch_out = Channel.empty()
    STAR_ALIGN.out.bam_sorted_aligned
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, bam: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    STAR_ALIGN.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
