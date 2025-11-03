include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'
include { STRINGTIE_CLEAN     } from '../../../modules/local/stringtie/clean/main'
include { STRANDEDNESS        } from '../../../modules/local/strandedness/main'

workflow ID6_STRINGTIE {

    take:
    ch_input

    main:

    STRANDEDNESS(
        ch_input.map { it -> tuple([id: it.experiment], it.infer) }
    )

    ch_strandedness = Channel.empty()
    STRANDEDNESS.out.infer
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .set { ch_strandedness }

    STRINGTIE_CLEAN(
        ch_input.map { it -> tuple([id: it.experiment], it.reference) }
    )

    ch_reference = Channel.empty()
    STRINGTIE_CLEAN.out.reference_clean
        .map { it -> [reference: it[1]] }
        .set { ch_reference }

    STRINGTIE_STRINGTIE(
        ch_input
        .combine(ch_strandedness)
        .map { a, b -> a + b }
        .map { it -> tuple(
            [id: it.experiment, alignment: it.alignment, strandedness: it.strandedness], 
            it.bam
        ) },
        ch_reference
        .map { it -> it.reference }
    )

    // clean

    ch_out = Channel.empty()
    STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, gtf: it[1]] }
        .set { ch_out }

    emit:
    ch_out
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

    emit:
    ch_out
}
