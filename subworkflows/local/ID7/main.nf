include { RMATS_LENGTH } from '../../../modules/local/rmats/length/main'
include { RMATS_PREP   } from '../../../modules/local/rmats/prep/main'
include { RMATS_POST   } from '../../../modules/local/rmats/post/main'

workflow ID7_RMATS_PREP {
    take:
    ch_input

    main:

    // arithmetic mean length

    RMATS_LENGTH(
        ch_input.map { it -> [id: it.condition, alignment: it.alignment] },
        ch_input.map { it -> it.stats }
    )

    ch_stats = Channel.empty()
    RMATS_LENGTH.out.stats
        .map { it -> [condition: it[0].id, alignment: it[0].alignment, length: it[1]] }
        .set { ch_stats }

    // join

    ch_combined = Channel.empty()

    ch_input
        .map { it -> tuple( [it.condition, it.alignment], it ) }
        .join(
            ch_stats
            .map { it -> tuple( [it.condition, it.alignment], it ) }
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_combined }

    // rmats

    RMATS_PREP(
        ch_combined.map { it -> tuple( [id: it.condition, alignment: it.alignment], it.gtf ) },
        ch_combined.map { it -> it.bam },
        ch_combined.map { it -> it.sequencing },
        ch_combined.map { it -> it.length },
        ch_combined.map { it -> it.strandedness }
    )

    ch_out = Channel.empty()
    ch_combined
        .map { it -> tuple( [it.condition, it.alignment], it ) }
        .join(
            RMATS_PREP.out.tmp
                .map { it -> [condition: it[0].id, alignment: it[0].alignment, tmp: it[1]] }
                .map { it -> tuple( [it.condition, it.alignment], it ) }
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RMATS_LENGTH.out.versions )
        .mix( RMATS_PREP.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow ID7_RMATS_POST {
    take:
    ch_input

    main:

    RMATS_POST(
        ch_input.map { it -> tuple( [id: it.condition, alignment: it.alignment], it.gtf ) },
        ch_input.map { it -> it.bam_1 },
        ch_input.map { it -> it.bam_2 },
        ch_input.map { it -> it.tmp_1 },
        ch_input.map { it -> it.tmp_2 },
        ch_input.map { it -> it.length_1 },
        ch_input.map { it -> it.length_2 },
        ch_input.map { it -> it.sequencing },
    )

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RMATS_POST.out.versions )

    emit:
    versions = ch_versions
}
