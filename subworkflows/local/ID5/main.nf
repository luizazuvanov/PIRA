include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment/main'
include { RSEQC_JUNCTIONANNOTATION } from '../../../modules/nf-core/rseqc/junctionannotation/main'
include { RSEQC_JUNCTIONSATURATION } from '../../../modules/nf-core/rseqc/junctionsaturation/main'
include { RSEQC_READDISTRIBUTION   } from '../../../modules/nf-core/rseqc/readdistribution/main'
include { STRANDEDNESS             } from '../../../modules/local/strandedness/main'

workflow ID5_RSEQC {

    take:
    ch_input

    main:

    RSEQC_INFEREXPERIMENT(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed }
    )

    RSEQC_JUNCTIONANNOTATION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed}
    )

    RSEQC_JUNCTIONSATURATION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed }
    )

    RSEQC_READDISTRIBUTION(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed }
    )

    // clean

    ch_out = Channel.empty()
    RSEQC_INFEREXPERIMENT.out.txt
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, infer: it[1]] }
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

workflow ID5_STRANDEDNESS {
    take:
    ch_input

    main:

    // strandedness

    STRANDEDNESS(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition], it.infer) }
    )

    ch_out = Channel.empty()
    STRANDEDNESS.out.infer
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( STRANDEDNESS.out.versions )

    emit:
    data = ch_out
    versions =  ch_versions
}
