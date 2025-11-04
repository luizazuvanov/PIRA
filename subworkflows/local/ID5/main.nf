include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment/main'
include { RSEQC_JUNCTIONANNOTATION } from '../../../modules/nf-core/rseqc/junctionannotation/main'
include { RSEQC_JUNCTIONSATURATION } from '../../../modules/nf-core/rseqc/junctionsaturation/main'
include { RSEQC_READDISTRIBUTION   } from '../../../modules/nf-core/rseqc/readdistribution/main'

workflow ID5 {

    take:
    ch_input

    main:

    RSEQC_INFEREXPERIMENT(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam) },
        ch_input.map { it -> it.bed }
    )

    RSEQC_JUNCTIONANNOTATION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam) },
        ch_input.map { it -> it.bed}
    )

    RSEQC_JUNCTIONSATURATION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam) },
        ch_input.map { it -> it.bed }
    )

    RSEQC_READDISTRIBUTION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment], it.bam) },
        ch_input.map { it -> it.bed }
    )

    // clean

    ch_out = Channel.empty()
    RSEQC_INFEREXPERIMENT.out.txt
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, infer: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RSEQC_INFEREXPERIMENT.out.versions )
        .mix( RSEQC_JUNCTIONANNOTATION.out.versions )
        .mix( RSEQC_JUNCTIONSATURATION.out.versions )
        .mix( RSEQC_READDISTRIBUTION.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}
