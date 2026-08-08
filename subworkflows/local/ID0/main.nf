include { BED                 } from '../../../modules/local/bed/main'
include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'

workflow GENOME_BED {

    take:
    ch_gtf

    main:

    BED(
        ch_gtf.map { it -> tuple([ id: "bed" ], it.gtf) }
    )

    // clean

    ch_out = Channel.empty()
    BED.out.bed
        .map { it -> [bed: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    BED.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}

workflow GENOME_INDEX {

    take:
    ch_fasta
    ch_gtf

    main:

    STAR_GENOMEGENERATE(
        ch_fasta.map { it -> tuple([ id: "index" ], it.fasta) },
        ch_gtf.map { it -> tuple([ id: "index" ], it.gtf) }
    )

    // clean

    ch_out = Channel.empty()
    STAR_GENOMEGENERATE.out.index
        .map { it -> [index: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    STAR_GENOMEGENERATE.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions

}
