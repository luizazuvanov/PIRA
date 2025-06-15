include { SRATOOLS_PREFETCH           } from '../../../modules/nf-core/sratools/prefetch'
include { SRATOOLS_FASTERQDUMP        } from '../../../modules/nf-core/sratools/fasterqdump'
include { CUSTOM_SRATOOLSNCBISETTINGS } from '../../../modules/nf-core/custom/sratoolsncbisettings'

workflow ID1 {

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

    SRATOOLS_FASTERQDUMP(
        SRATOOLS_PREFETCH.out.sra, 
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings, 
        []
    )

    // clean
    ch_out = Channel.empty()
    SRATOOLS_FASTERQDUMP.out.reads
        .map { it -> tuple(run: it[0].id, out: it[1]) }
        .map { it -> it[0]}
        .set { ch_out }

    // join
    ch_out = ch_input
        .map { it -> tuple(it.run, it) }
        .join( 
            ch_out
            .map {it -> tuple(it.run, it)}
        )
        .map { __, a, b -> a + b } // drop join key

    emit:
    ch_out
}