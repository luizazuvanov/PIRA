include { SAMTOOLS_INDEX } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_MERGE } from '../../../modules/nf-core/samtools/merge/main'
include { SAMTOOLS_STATS } from '../../../modules/nf-core/samtools/stats/main'

workflow ID4_EXPERIMENT {
    
    take:
    ch_input

    main:

    SAMTOOLS_STATS(
        ch_input.map { it -> tuple(
            [id: it.experiment, alignment: it.alignment], 
            it.bam.findAll { it.name.endsWith('.Aligned.sortedByCoord.out.bam')},
            []
        ) },
        [[], []]
    )

    SAMTOOLS_INDEX(
        ch_input.map { it -> tuple(
            [id: it.experiment, alignment: it.alignment], 
            it.bam.findAll { it.name.endsWith('.Aligned.sortedByCoord.out.bam')}
        ) }
    )
}


workflow ID4_CONDITION {
    
    take:
    ch_input

    main:

    SAMTOOLS_MERGE(
        ch_input.map { it -> tuple(
            [id: it.condition, alignment: it.alignment], 
            it.bam.findAll { it.name.endsWith('.Aligned.sortedByCoord.out.bam')}
        ) },
        [[], []],
        [[], []],
        [[], []] 
    )

    SAMTOOLS_INDEX(
        SAMTOOLS_MERGE.out.bam
    )
}