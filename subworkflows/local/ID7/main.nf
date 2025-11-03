include { RMATS        } from '../../../modules/local/rmats/main'
include { STRANDEDNESS } from '../../../modules/local/strandedness/main'

workflow ID7 {
    take:
    ch_input

    main:

    STRANDEDNESS(
        ch_input.map { it -> tuple([id: it.alignment], it.infer) }
    )

    ch_strandedness = Channel.empty()
    STRANDEDNESS.out.infer
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .set { ch_strandedness }

    RMATS(
        ch_input.map { it -> tuple([id: it.alignment], it.gtf) },
        ch_input.map { it -> it.bam_1 },
        ch_input.map { it -> it.bam_2 },
        ch_input.map { it -> it.stats },
        ch_strandedness.map { it -> it.sequencing },
        ch_strandedness.map { it -> it.strandedness },
    )
}
