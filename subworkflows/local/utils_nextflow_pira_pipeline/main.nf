//
// Subworkflow with functionality specific to the nf-core/pira pipeline
//

workflow group_fastp_by_exp_cond_end {

    take:
    ch_fastp // [exp, cond, end, []fastp]

    main:

    ch_out = channel.empty()
    ch_fastp
        .map { it -> tuple(it.experiment, it.condition, it.single_end, it) }
        .groupTuple(by: [0, 1, 2])
        .map { experiment, condition, single_end, its -> [
            experiment: experiment,
            condition: condition,
            single_end: single_end,
            fastp: its.collect { it -> it.fastp }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // exp, cond, end, []fastp
}

workflow group_gtf {

    take:
    ch_gtf // [gtf, ...]

    main:

    ch_out = channel.empty()
    ch_gtf
        .collect()
        .map { its -> [
            gtf: its.collect { it -> it.gtf }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // []gtf
}

workflow group_stats {

    take:
    ch_gtf // [gtf, ...]

    main:

    ch_out = channel.empty()
    ch_gtf
        .collect()
        .map { its -> [
            stats: its.collect { it -> it.stats }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // []stats
}

workflow group_bam_by_cond {

    take:
    ch_bam // [cond, bam, ...]

    main:

    ch_out = channel.empty()
    ch_bam
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it -> it.condition }.unique().first(),
            bam: its.collect { it -> it.bam }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, []bam
}

workflow group_spl_by_alignment {

    take:
    ch_spl // [alignment, spl, ...]

    main:

    ch_out = channel.empty()
    ch_spl
        .map { it -> tuple(it.alignment, it) }
        .groupTuple()
        .map { __, its -> [
            alignment: its.collect { it -> it.alignment }.unique().first(),
            spl: its.collect { it -> it.spl }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // alignment, []spl
}

workflow combine_by_cond {

    take:
    ch_a // cond, ...
    ch_b // cond, ...

    main:

    ch_out = channel.empty()

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

    ch_out = channel.empty()

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

    ch_out = channel.empty()

    ch_input
        .collect()
        .flatMap { items ->
            def combinations = []
            def sorted = items.sort { it -> it.condition }
            sorted.eachWithIndex { cond_1, i ->
                sorted.drop(i + 1).each { cond_2 ->
                    combinations << [
                        condition: "${cond_1.condition}_vs_${cond_2.condition}",
                        bam_1: cond_1.bam,
                        bam_2: cond_2.bam,
                        tmp_1: cond_1.tmp,
                        tmp_2: cond_2.tmp,
                        length: cond_1.length,
                        sequencing: [cond_1.sequencing, cond_2.sequencing],
                    ]
                }
            }
            return combinations
        }
        .set { ch_out }

    emit:
    ch_out // [cond1_vs_cond2, ...]
}

workflow reduce_strandedness_by_cond {

    take:
    ch_strandedness // [cond, alias, strandedness, sequencing]

    main:

    ch_out = channel.empty()
    ch_strandedness
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it -> it.condition }.unique().first(),
            alias: its.collect { it -> it.alias }.first(),
            sequencing: its.collect { it -> it.sequencing }.first(),
            strandedness: its.collect { it -> it.strandedness }.first()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, alias, strandedness, sequencing
}
