include { FASTP } from '../../../modules/nf-core/fastp'

workflow ID2 {

    take:
    ch_input

    main:

    def single_end = ch_input.map { it -> it.fastq }.collect().size() == 1

    FASTP(
        ch_input.map { it -> tuple([id: it.run, single_end: single_end], it.fastq) }, 
        [],
        false,
        false,
        false,
    )

    // clean

    ch_out = Channel.empty()
    FASTP.out.reads
        .map { it -> [run: it[0].id, fastp: it[1]] }
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