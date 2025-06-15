include { FASTP } from '../../../modules/nf-core/fastp'

workflow ID2 {

    take:
    ch_reads

    main:
    println ch_reads
}