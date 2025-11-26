include { SJ_FILTER } from '../../../modules/local/sj/filter/main'
include { STAR_ALIGN } from '../../../modules/nf-core/star/align/main'
include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'

workflow ID3_INDEX {

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
    ch_versions
        .mix( STAR_GENOMEGENERATE.out.versions )

    emit:
    data = ch_out
    versions = ch_versions

}

workflow ID3_NOVO {

    take:
    ch_input

    main:

    def single_end = ch_input.map { it -> it.fastp }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition, single_end: single_end], it.fastp) },
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        [[], []],
        true,
        "",
        ""
    )

    SJ_FILTER(
        STAR_ALIGN.out.spl_junc_tab.map { it -> tuple([id: it[0].id, alignment: it[0].alignment, condition: it[0].condition], it[1]) }
    )

    // clean

    ch_out_bam = Channel.empty()
    STAR_ALIGN.out.bam_sorted_aligned
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, bam: it[1]] }
        .set { ch_out_bam }

    ch_out_spl = Channel.empty()
    SJ_FILTER.out.spl_junc_tab
        .map { it -> [experiment: it[0].id, condition: it[0].condition, spl: it[1]] }
        .set { ch_out_spl }

    // join

    ch_out = ch_out_bam
        .map { it -> tuple(it.experiment, it) }
        .join(
            ch_out_spl
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( STAR_ALIGN.out.versions )
        .mix( SJ_FILTER.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}

workflow ID3_DENOVO {

    take:
    ch_input

    main:

    def single_end = ch_input.map { it -> it.fastp }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, alignment: it.alignment, condition: it.condition, single_end: single_end, spl: it.spl], it.fastp) },
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        [[], []],
        true,
        "",
        ""
    )

    // clean

    ch_out = Channel.empty()
    STAR_ALIGN.out.bam_sorted_aligned
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, condition: it[0].condition, bam: it[1]] }
        .set { ch_out }

    // versions

    ch_versions = Channel.empty()
    ch_versions
        .mix( STAR_ALIGN.out.versions )

    emit:
    data = ch_out
    versions = ch_versions
}
