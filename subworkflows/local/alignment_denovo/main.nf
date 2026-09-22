include { STAR_ALIGN } from '../../../modules/nf-core/star/align/main'

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

    ch_out = channel.empty()
    STAR_ALIGN.out.bam_sorted_aligned
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, bam: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    STAR_ALIGN.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
