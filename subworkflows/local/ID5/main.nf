include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment'
include { RSEQC_JUNCTIONANNOTATION } from '../../../modules/nf-core/rseqc/junctionannotation'
include { RSEQC_JUNCTIONSATURATION } from '../../../modules/nf-core/rseqc/junctionsaturation'
include { RSEQC_READDISTRIBUTION   } from '../../../modules/nf-core/rseqc/readdistribution'

workflow ID5 {
    take:
    ch_input
    ch_bed

    main:
    
    ch_input.view()
    ch_bed.view()

    RSEQC_INFEREXPERIMENT(
        ch_input.map { it -> tuple([id: it.experiment], it.bam)},
        ch_bed.map { it -> it.bed}
    )

    RSEQC_INFEREXPERIMENT.out.txt.view()

    ch_out = Channel.empty()

    emit:
    ch_out
}