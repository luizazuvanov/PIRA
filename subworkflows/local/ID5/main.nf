include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment/main'
include { RSEQC_JUNCTIONANNOTATION } from '../../../modules/nf-core/rseqc/junctionannotation/main'
include { RSEQC_JUNCTIONSATURATION } from '../../../modules/nf-core/rseqc/junctionsaturation/main'
include { RSEQC_READDISTRIBUTION   } from '../../../modules/nf-core/rseqc/readdistribution/main'
include { STRANDEDNESS             } from '../../../modules/local/strandedness/main'

workflow CTRL3 {

    take:
    ch_input

    main:

    RSEQC_INFEREXPERIMENT(
        ch_input.map { it -> tuple([id: it.experiment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed }
    )

    STRANDEDNESS(
        RSEQC_INFEREXPERIMENT.out.txt
            .map { it -> tuple([id: it[0].id, condition: it[0].condition], it[1]) }
    )

    RSEQC_JUNCTIONANNOTATION(
        ch_input.map { it -> tuple([id: it.experiment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed}
    )

    RSEQC_JUNCTIONSATURATION(
        ch_input.map { it -> tuple([id: it.experiment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed }
    )

    RSEQC_READDISTRIBUTION(
        ch_input.map { it -> tuple([id: it.experiment, condition: it.condition], it.bam) },
        ch_input.map { it -> it.bed }
    )

    // clean

    ch_out = Channel.empty()
    STRANDEDNESS.out.infer
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RSEQC_INFEREXPERIMENT.out.versions )
        .mix( STRANDEDNESS.out.versions )
        .mix( RSEQC_JUNCTIONANNOTATION.out.versions )
        .mix( RSEQC_JUNCTIONSATURATION.out.versions )
        .mix( RSEQC_READDISTRIBUTION.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}
