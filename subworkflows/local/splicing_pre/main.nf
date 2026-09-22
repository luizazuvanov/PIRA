include { RMATS_PRE   } from '../../../modules/local/rmats/prep/main'

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

    ch_out = channel.empty()
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

    ch_versions = channel.empty()
    RMATS_PRE.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
