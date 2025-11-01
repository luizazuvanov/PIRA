include { STAR_ALIGN } from '../../../modules/nf-core/star/align/main'
include { SJ_FILTER } from '../../../modules/local/sj/filter/main'

workflow ID3_NOVO {
    
    take:
    ch_input

    main:
    
    def single_end = ch_input.map { it -> it.fastp }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, single_end: single_end], it.fastp) }, 
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        [[], []],
        true,
        "",
        ""
    )

    SJ_FILTER(
        STAR_ALIGN.out.spl_junc_tab.map { it -> tuple([id: it[0].id], it[1]) }
    )

    // clean

    ch_out_bam = Channel.empty()
    STAR_ALIGN.out.bam_sorted_aligned
        .map { it -> [experiment: it[0].id, bam: it[1]] }
        .set { ch_out_bam }

    ch_out_spl = Channel.empty()
    SJ_FILTER.out.spl_junc_tab
        .map { it -> [experiment: it[0].id, spl: it[1]] }
        .set { ch_out_spl }

    // join

    ch_out = ch_out_bam
        .map { it -> tuple(it.experiment, it) }
        .join( 
            ch_out_spl
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key

    emit:
    ch_out
}

workflow ID3_DENOVO {
    
    take:
    ch_input

    main:
    
    def single_end = ch_input.map { it -> it.fastp }.collect().size() == 1

    STAR_ALIGN(
        ch_input.map { it -> tuple([id: it.experiment, single_end: single_end, spl: it.spl], it.fastp) }, 
        ch_input.map { it -> tuple([id: it.experiment], it.index) },
        [[], []],
        true,
        "",
        ""
    )

    // clean

    ch_out = Channel.empty()
    STAR_ALIGN.out.bam
        .map { it -> [experiment: it[0].id, bam: it[1]] }
        .set { ch_out }

    emit:
    ch_out
}