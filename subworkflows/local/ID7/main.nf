include { RMATS        } from '../../../modules/local/rmats/main'
include { STRANDEDNESS } from '../../../modules/local/strandedness/main'

workflow ID7 {
    take:
    ch_input

    main:
    ch_input.view()
}