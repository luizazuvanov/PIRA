include { BED } from '../../../modules/local/bed/main'

workflow GENOME_BED {

    take:
    ch_gtf

    main:

    BED(
        ch_gtf.map { it -> tuple([ id: "bed" ], it.gtf) }
    )

    // clean

    ch_out = channel.empty()
    BED.out.bed
        .map { it -> [bed: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    BED.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
