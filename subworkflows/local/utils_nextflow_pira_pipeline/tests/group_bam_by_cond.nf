include { group_bam_by_cond } from '../main.nf'

workflow TEST_GROUP_BAM_BY_COND {

    take:
    ch_input

    main:
    result = group_bam_by_cond(ch_input)

    emit:
    out = result

}
