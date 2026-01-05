include { SRATOOLS_PREFETCH           } from '../../../modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP        } from '../../../modules/nf-core/sratools/fasterqdump/main'
include { CUSTOM_SRATOOLSNCBISETTINGS } from '../../../modules/nf-core/custom/sratoolsncbisettings/main'

workflow SAMPLES {

    take:
    ch_input

    main:

    CUSTOM_SRATOOLSNCBISETTINGS(
        []
    )

    SRATOOLS_PREFETCH(
        ch_input.map { it -> tuple([id: it.run, single_end: it.single_end], it.run) },
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings,
        []
    )

    SRATOOLS_FASTERQDUMP(
        SRATOOLS_PREFETCH.out.sra,
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings,
        []
    )

    // clean

    ch_out = Channel.empty()
    SRATOOLS_FASTERQDUMP.out.reads
        .map { it -> [run: it[0].id, single_end: it[0].single_end, fastq: it[1]] }
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
    ch_versions
        .mix( CUSTOM_SRATOOLSNCBISETTINGS.out.versions )
        .mix( SRATOOLS_PREFETCH.out.versions )
        .mix( SRATOOLS_FASTERQDUMP.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}
