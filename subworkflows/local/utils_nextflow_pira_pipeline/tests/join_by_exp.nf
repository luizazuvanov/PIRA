include { join_by_exp } from '../main.nf'

workflow TEST_JOIN_BY_EXP {

    take:
    ch_a
    ch_b

    main:
    result = join_by_exp(ch_a, ch_b)

    emit:
    out = result

}
