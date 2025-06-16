include { STAR_ALIGN } from '../../../modules/nf-core/star/align'


workflow ID3 {
    
    take:
    ch_input

    main:
    
    def single_end = ch_input.map { it -> it.out }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, single_end: single_end], it.out) }, 
        ch_input.map { it -> tuple([id: it.experiment, single_end: single_end], '/dev/null/abc') }, // TODO: check index dir
        ch_input.map { it -> tuple([id: it.experiment, single_end: single_end], '/dev/null/def') }, // TODO: ch
        true,
        "",
        ""
    )

    // clean
    ch_out = Channel.empty()
    STAR_ALIGN.out.bam // TODO: check which BAM file to use
        .map { it -> tuple(experiment: it[0].id, out: it[1]) }
        .map { it -> it.first() }
        .set { ch_out }

    ch_out.view()

    emit:
    ch_out
}