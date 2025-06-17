include { STAR_ALIGN } from '../../../modules/nf-core/star/align'


workflow ID4 {
    
    take:
    ch_input

    main:
    
    def single_end = ch_input.map { it -> it.fastp }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, single_end: single_end], it.fastp) }, 
        ch_input.map { __ -> tuple([], '/dev/null/abc' ) },
        ch_input.map { it -> tuple([], it.spl) },
        false,
        "",
        ""
    )

    // clean

    ch_out = Channel.empty()
    STAR_ALIGN.out.bam
        .map { it -> tuple(experiment: it[0].id, bam: it[1]) }
        .map { it -> it.first() }
        .set { ch_out }

    emit:
    ch_out
}