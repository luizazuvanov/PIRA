include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'
include { STRINGTIE_CLEAN     } from '../../../modules/local/stringtie/clean/main'

workflow ID6_CLEAN {

    take:
    ch_input

    main:

    STRINGTIE_CLEAN(
        ch_input.map { it -> tuple([id: "gtf", alignment: "denovo"], it.gtf) }
    )

    ch_out = Channel.empty()
    STRINGTIE_CLEAN.out.gtf_clean
        .map { it -> [reference: it] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( STRINGTIE_CLEAN.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow ID6_STRINGTIE {

    take:
    ch_input

    main:

    STRINGTIE_STRINGTIE(
        ch_input
        .map { it -> tuple(
            [id: it.experiment, alignment: it.alignment, condition: it.condition, strandedness: it.strandedness],
            it.bam
        ) },
        ch_input
        .map { it -> it.reference }
    )

    // clean

    ch_out = Channel.empty()
    STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, gtf: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( STRINGTIE_STRINGTIE.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow ID6_MERGE {

    take:
    ch_input

    main:

    STRINGTIE_MERGE(
        ch_input.map { it -> it.gtf },
        ch_input.map { it -> it.reference }
    )

    // clean

    ch_out = Channel.empty()
    ch_input
        .combine(STRINGTIE_MERGE.out.gtf)
        .map { row, gtf -> [alignment: row.alignment, gtf: gtf] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( STRINGTIE_MERGE.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}
