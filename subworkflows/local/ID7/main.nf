include { RMATS        } from '../../../modules/local/rmats/main'
include { STRANDEDNESS } from '../../../modules/local/strandedness/main'

workflow ID7 {
    take:
    ch_input

    main:

    STRANDEDNESS(
        ch_input.map { it -> tuple([id: it.alignment], it.infer) }
    )

    ch_input
        .mix(
            STRANDEDNESS.out.infer
                .map { it -> file(it) }
                .splitCsv( header: true, strip: true )
        )
        .set { ch_input }

    RMATS(
        ch_input.map { it -> tuple([id: it.alignment], it.gtf) },
        ch_input.map { it -> it.bam_1 },
        ch_input.map { it -> it.bam_2 },
        ch_input.map { it -> it.sequencing},
        ch_input.map { __ -> 150 }, // default read length
        ch_input.map { it -> it.strandedness},
    )
}
