//
// Subworkflow with functionality specific to the nf-core/pira pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO GROUP / COMBINE / JOIN CHANNELS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow group_gtf_by_align {

    take:
    ch_gtf // [align, gtf, ...]

    main:

    ch_out = Channel.empty()
    ch_gtf
        .map { it -> tuple(it.alignment, it) }
        .groupTuple()
        .map { __, its -> [
            alignment: its.collect { it.alignment }.unique().first(),
            gtf: its.collect { it.gtf }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // align, []gtf
}

workflow group_stats_by_align {

    take:
    ch_stats // [align, stats, ...]

    main:

    ch_out = Channel.empty()
    ch_stats
        .map { it -> tuple(it.alignment, it) }
        .groupTuple()
        .map { __, its -> [
            alignment: its.collect { it.alignment }.unique().first(),
            stats: its.collect { it.stats }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // align, []stats
}

workflow group_bam_by_cond_keep_align {

    take:
    ch_bam // [cond, align, bam, ...]

    main:

    ch_out = Channel.empty()
    ch_bam
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it.condition }.unique().first(),
            alignment: its.collect { it.alignment }.unique().first(),
            bam: its.collect { it.bam }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, align, []bam
}

workflow combine_by_cond {

    take:
    ch_a // cond, ...
    ch_b // cond, ...

    main:

    ch_out = Channel.empty()

    ch_a
        .map { it -> tuple(it.condition, it) }
        .combine(
            ch_b.map {it -> tuple(it.condition, it)},
            by: 0
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_out }

    emit:
    ch_out // cond, ...
}

workflow join_by_exp {

    take:
    ch_a // exp, ...
    ch_b // exp, ...

    main:

    ch_out = Channel.empty()

    ch_a
        .map { it -> tuple(it.experiment, it) }
        .join(
            ch_b.map {it -> tuple(it.experiment, it)},
            failOnDuplicate: true,
            remainder: false
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_out }

    emit:
    ch_out // exp, ...
}

workflow compute_pairs_by_cond {

    take:
    ch_input // [cond, ...], [cond, ...]

    main:

    ch_out = Channel.empty()

    ch_input
        .collect()
        .flatMap { items ->
            def combinations = []
            for (int i = 0; i < items.size(); i++) {
                for (int j = i + 1; j < items.size(); j++) {
                    def cond_1 = items[i]
                    def cond_2 = items[j]
                    def combined = [
                        condition: "${cond_1.condition}_vs_${cond_2.condition}",
                        bam_1: cond_1.bam,
                        bam_2: cond_2.bam,
                        tmp_1: cond_1.tmp,
                        tmp_2: cond_2.tmp,
                        length: cond_1.length,
                        alignment: cond_1.alignment, // both have same alignment
                        sequencing: [cond_1.sequencing, cond_2.sequencing],
                    ]
                    combinations.add(combined)
                }
            }
            return combinations
        }
        .set { ch_out }

    emit:
    ch_out // [cond1_vs_cond2, ...]
}

workflow reduce_strandedness_by_cond_align {

    take:
    ch_strandedness // [cond, align, alias, strandedness, sequencing]

    main:

    ch_out = Channel.empty()
    ch_strandedness
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it.condition }.unique().first(),
            alignment: its.collect { it.alignment }.unique().first(),
            alias: its.collect { it.alias }.first(),
            sequencing: its.collect { it.sequencing }.first(),
            strandedness: its.collect { it.strandedness }.first()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, align, alias, strandedness, sequencing
}
