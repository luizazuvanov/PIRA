include { reduce_strandedness_by_cond } from '../main.nf'

workflow TEST_REDUCE_STRANDEDNESS_BY_COND {

    take:
    ch_input

    main:
    result = reduce_strandedness_by_cond(ch_input)

    emit:
    out = result

}
