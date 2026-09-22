include { compute_pairs_by_cond } from '../main.nf'

workflow TEST_COMPUTE_PAIRS_BY_COND {

    take:
    ch_input

    main:
    result = compute_pairs_by_cond(ch_input)

    emit:
    out = result

}
