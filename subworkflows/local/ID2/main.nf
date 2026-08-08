include { FASTP } from '../../../modules/local/fastp/main'

workflow CTRL1 {

    take:
    ch_input

    main:

    FASTP(
        ch_input.map { it -> tuple([id: it.run, single_end: it.single_end], it.fastq) },
        [],
        false,
        false,
        false,
    )

    // clean

    ch_out = Channel.empty()
    FASTP.out.reads
        .map { it -> [run: it[0].id, single_end: it[0].single_end, fastp: it[1]] }
        .set { ch_out }

    // join

    ch_out = ch_input
        .map { it -> [run: it.run, experiment: it.experiment, condition: it.condition, single_end: it.single_end] }
        .map { it -> tuple(it.run, it) }
        .join(
            ch_out
            .map {it -> tuple(it.run, it)}
        )
        .map { __, a, b -> a + b } // drop join key

    // versions

    ch_versions = Channel.empty()
    FASTP.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
