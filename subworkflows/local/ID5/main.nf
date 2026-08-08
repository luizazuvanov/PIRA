include { RSEQC_INFEREXPERIMENT    } from '../../../modules/nf-core/rseqc/inferexperiment/main'
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

    // clean

    ch_out = Channel.empty()
    STRANDEDNESS.out.infer
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    RSEQC_INFEREXPERIMENT.out.versions
        .mix( STRANDEDNESS.out.versions )
        .set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
