include { group_gtf } from '../main'

workflow TEST_GROUP_GTF {

    take:
    ch_input

    main:
    ch_out = group_gtf(ch_input)

    emit:
    out = ch_out
}
