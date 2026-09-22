include { group_spl_by_alignment } from '../main.nf'

workflow TEST_GROUP_SPL_BY_ALIGNMENT {

    take:
    ch_input

    main:
    result = group_spl_by_alignment(ch_input)

    emit:
    out = result

}
