include { SAMTOOLS_INDEX } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_STATS } from '../../../modules/nf-core/samtools/stats/main'

workflow CTRL2 {

    take:
    ch_input

    main:

    SAMTOOLS_STATS(
        ch_input.map { it -> tuple(
            [id: it.experiment, condition: it.condition],
            it.bam,
            []
        ) },
        [[], []]
    )

    SAMTOOLS_INDEX(
        ch_input.map { it -> tuple(
            [id: it.experiment],
            it.bam,
        ) }
    )

    ch_out = channel.empty()
    SAMTOOLS_STATS.out.stats
        .map { it -> [experiment: it[0].id, condition: it[0].condition, stats: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    ch_versions
        .mix( SAMTOOLS_STATS.out.versions )
        .mix( SAMTOOLS_INDEX.out.versions )

    ch_multiqc = SAMTOOLS_STATS.out.stats
        .map { _meta, report -> report }

    emit:
    data     = ch_out
    multiqc  = ch_multiqc
    versions = ch_versions
}
