include { SRATOOLS_PREFETCH           } from '../../../modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP        } from '../../../modules/nf-core/sratools/fasterqdump/main'
include { CUSTOM_SRATOOLSNCBISETTINGS } from '../../../modules/nf-core/custom/sratoolsncbisettings/main'

workflow ID1_FETCH {

    take:
    ch_input

    main:

    CUSTOM_SRATOOLSNCBISETTINGS(
        []
    )

    SRATOOLS_PREFETCH(
        ch_input.map { it -> tuple([id: it.run], it.run) },
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings,
        []
    )

    // SRATOOLS_FASTERQDUMP(
    //     SRATOOLS_PREFETCH.out.sra,
    //     CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings,
    //     []
    // )

    // clean

    ch_out = Channel.empty()
    SRATOOLS_PREFETCH.out.sra
        .map { it -> [run: it[0].id, sra: it[1]] }
        .set { ch_out }

    // ch_out = Channel.empty()
    // SRATOOLS_FASTERQDUMP.out.reads
    //     .map { it -> [run: it[0].id, fastq: it[1]] }
    //     .set { ch_out }

    // join

    ch_out = ch_input
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
        // .mix( SRATOOLS_FASTERQDUMP.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow ID1_SERIALISE {

    take:
    ch_input

    main:

    CUSTOM_SRATOOLSNCBISETTINGS(
        []
    )

    // SRATOOLS_PREFETCH(
    //     ch_input.map { it -> tuple([id: it.run], it.run) },
    //     CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings,
    //     []
    // )

    SRATOOLS_FASTERQDUMP(
        ch_input.map { it -> tuple([id: it.run], it.sra) },
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings,
        []
    )

    // clean

    ch_out = Channel.empty()
    SRATOOLS_FASTERQDUMP.out.reads
        .map { it -> [run: it[0].id, fastq: it[1]] }
        .set { ch_out }

    // join

    ch_out = ch_input
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
        // .mix( SRATOOLS_PREFETCH.out.versions )
        .mix( SRATOOLS_FASTERQDUMP.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}
