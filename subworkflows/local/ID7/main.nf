include { RMATS_LENGTH } from '../../../modules/local/rmats/length/main'
include { RMATS_PRE   } from '../../../modules/local/rmats/prep/main'
include { RMATS_POS   } from '../../../modules/local/rmats/post/main'

workflow SPLICING_LENGTH {
    take:
    ch_input

    main:

    RMATS_LENGTH(
        ch_input.map { it -> [id: "length"] },
        ch_input.map { it -> it.stats }
    )

    ch_out = Channel.empty()
    RMATS_LENGTH.out.stats
        .map { it -> [length: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RMATS_LENGTH.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow SPLICING_PRE {
    take:
    ch_input

    main:

    RMATS_PRE(
        ch_input.map { it -> tuple( [id: it.condition], it.gtf ) },
        ch_input.map { it -> it.bam },
        ch_input.map { it -> it.sequencing },
        ch_input.map { it -> it.length },
        ch_input.map { it -> it.strandedness }
    )

    ch_out = Channel.empty()
    ch_input
        .map { it -> tuple( [it.condition], it ) }
        .join(
            RMATS_PRE.out.tmp
                .map { it -> [condition: it[0].id, tmp: it[1]] }
                .map { it -> tuple( [it.condition], it ) }
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RMATS_PRE.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow SPLICING_POS {
    take:
    ch_input

    main:

    RMATS_POS(
        ch_input.map { it -> tuple( [id: it.condition], it.gtf ) },
        ch_input.map { it -> it.bam_1 },
        ch_input.map { it -> it.bam_2 },
        ch_input.map { it -> it.tmp_1 },
        ch_input.map { it -> it.tmp_2 },
        ch_input.map { it -> it.sequencing },
        ch_input.map { it -> it.length },
    )

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( RMATS_POS.out.versions )

    emit:
    versions = ch_versions
}
