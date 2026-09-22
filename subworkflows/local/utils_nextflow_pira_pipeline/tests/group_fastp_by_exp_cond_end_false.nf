include { group_fastp_by_exp_cond_end } from '../main.nf'

workflow TEST_GROUP_FASTP_BY_EXP_COND_END_FALSE {

    take:
    ch_input

    main:
    result = group_fastp_by_exp_cond_end(ch_input)

    emit:
    out = result

}
