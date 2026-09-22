include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'

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

    ch_out = channel.empty()
    STAR_GENOMEGENERATE.out.index
        .map { it -> [index: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = channel.empty()
    STAR_GENOMEGENERATE.out.versions.set { ch_versions }

    emit:
    data = ch_out
    versions = ch_versions
}
