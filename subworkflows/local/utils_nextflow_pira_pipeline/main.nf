workflow UTILS_NEXTFLOW_PIRA_PIPELINE {

    main:
    log.info("")

    emit:
    dummy_emit = true
}

def group_fastp_by_exp_cond_end(ch_fastp) {
    // [exp, cond, end, []fastp]
    return ch_fastp
        .map { it -> tuple(it.experiment, it.condition, it.single_end, it) }
        .groupTuple(by: [0, 1, 2])
        .map { experiment, condition, single_end, its -> [
            experiment: experiment,
            condition: condition,
            single_end: single_end,
            fastp: its.collect { it -> it.fastp }.flatten()
        ] }
}

def group_gtf(ch_gtf) {
    // [gtf, ...]
    return ch_gtf
        .collect()
        .map { its -> [
            gtf: its.collect { it -> it.gtf }.flatten()
        ] }
}

def group_stats(ch_gtf) {
    // [stats, ...]
    return ch_gtf
        .collect()
        .map { its -> [
            stats: its.collect { it -> it.stats }.flatten()
        ] }
}

def group_bam_by_cond(ch_bam) {
    // [cond, bam, ...]
    return ch_bam
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it -> it.condition }.unique().first(),
            bam: its.collect { it -> it.bam }.flatten()
        ] }
}

def group_spl_by_alignment(ch_spl) {
    // [alignment, spl, ...]
    return ch_spl
        .map { it -> tuple(it.alignment, it) }
        .groupTuple()
        .map { __, its -> [
            alignment: its.collect { it -> it.alignment }.unique().first(),
            spl: its.collect { it -> it.spl }.flatten()
        ] }
}

def combine_by_cond(ch_a, ch_b) {
    // cond, ...
    return ch_a
        .map { it -> tuple(it.condition, it) }
        .combine(
            ch_b.map {it -> tuple(it.condition, it)},
            by: 0
        )
        .map { __, a, b -> a + b } // drop join key
}

def join_by_exp(ch_a, ch_b) {
    // exp, ...
    return ch_a
        .map { it -> tuple(it.experiment, it) }
        .join(
            ch_b.map {it -> tuple(it.experiment, it)},
            failOnDuplicate: true,
            remainder: false
        )
        .map { __, a, b -> a + b } // drop join key
}

def compute_pairs_by_cond(ch_input) {
    // [cond, ...], [cond, ...]
    return ch_input
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
}

def reduce_strandedness_by_cond(ch_strandedness) {
    // [cond, alias, strandedness, sequencing]
    return ch_strandedness
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it -> it.condition }.unique().first(),
            alias: its.collect { it -> it.alias }.first(),
            sequencing: its.collect { it -> it.sequencing }.first(),
            strandedness: its.collect { it -> it.strandedness }.first()
        ] }
}
