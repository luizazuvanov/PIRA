include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment'
include { RSEQC_JUNCTIONANNOTATION } from '../../../modules/nf-core/rseqc/junctionannotation'
include { RSEQC_JUNCTIONSATURATION } from '../../../modules/nf-core/rseqc/junctionsaturation'
include { RSEQC_READDISTRIBUTION   } from '../../../modules/nf-core/rseqc/readdistribution'

workflow ID5 {

    take:
    ch_input

    main:

    RSEQC_INFEREXPERIMENT(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam)},
        ch_input.map { it -> it.bed}
    )

    RSEQC_JUNCTIONANNOTATION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam)},
        ch_input.map { it -> it.bed}
    )

    RSEQC_JUNCTIONSATURATION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam)},
        ch_input.map { it -> it.bed}
    )

    RSEQC_READDISTRIBUTION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam)},
        ch_input.map { it -> it.bed}
    )
}