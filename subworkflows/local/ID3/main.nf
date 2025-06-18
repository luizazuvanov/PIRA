include { STAR_ALIGN } from '../../../modules/nf-core/star/align'

workflow ID3 {
    
    take:
    ch_input

    main:
    
    def single_end = ch_input.map { it -> it.fastp }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, index: it.index, single_end: single_end], it.fastp) }, 
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        ch_input.map { it -> tuple([id: it.experiment], '/dev/null' ) },
        true,
        "",
        ""
    )

    // clean

    ch_out = Channel.empty()
    STAR_ALIGN.out.spl_junc_tab
        .map { it -> tuple(experiment: it[0].id, index: it[0].index, spl: it[1]) }
        .map { it -> it.first() }
        .set { ch_out }

    emit:
    ch_out
}