include { combine_by_cond } from '../main.nf'

workflow TEST_COMBINE_BY_COND {

    take:
    ch_a
    ch_b

    main:
    result = combine_by_cond(ch_a, ch_b)

    emit:
    out = result

}
