include { group_stats } from '../main'

workflow TEST_GROUP_STATS {

    take:
    ch_input

    main:
    ch_out = group_stats(ch_input)

    emit:
    out = ch_out
}
