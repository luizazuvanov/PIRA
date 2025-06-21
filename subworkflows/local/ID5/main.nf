include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment/main'
include { RSEQC_JUNCTIONANNOTATION } from '../../../modules/nf-core/rseqc/junctionannotation/main'
include { RSEQC_JUNCTIONSATURATION } from '../../../modules/nf-core/rseqc/junctionsaturation/main'
include { RSEQC_READDISTRIBUTION   } from '../../../modules/nf-core/rseqc/readdistribution/main'

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