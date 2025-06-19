/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID1 } from '../../subworkflows/local/ID1'
include { ID2 } from '../../subworkflows/local/ID2'
include { ID3 } from '../../subworkflows/local/ID3'
include { ID4 } from '../../subworkflows/local/ID4'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIRA {    

    take:
    // run, exp, cond, idx
    ch_samples

    main:

    //
    // SUBWORKFLOW: ID1
    //

    println "ID1"
    ch_fastq = ID1(ch_samples) // run, exp, cond, idx, []fastq

    //
    // SUBWORKFLOW: ID2
    //

    println "ID2"
    ch_fastp = ID2(ch_fastq) // run, exp, cond, idx, []fastp

    //
    // SUBWORKFLOW: ID3
    //

    println "ID3"
    ch_fastp_by_exp_idx = group_fastp_by_exp_idx(ch_fastp) // exp, idx, []fastp
    ch_novo = ID3(ch_fastp_by_exp_idx) // exp, idx, []bam, spl
    ch_novo.view()

    //
    // SUBWORKFLOW: ID4
    //

    println "ID4"
    ch_fastp_bam_spl_by_exp_idx = join_fastp_bam_spl_by_exp_idx(ch_fastp_by_exp_idx, ch_novo) // exp, idx, []fastp, spl
    ch_denovo = ID4(ch_fastp_bam_spl_by_exp_idx) // exp, idx, []bam
    ch_denovo.view()
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow group_fastp_by_exp_idx {

    take:
    ch_fastp // run, experiment, condition, index

    main:

    ch_fastp_by_exp_idx = Channel.empty()
    ch_fastp
        .map { it -> tuple(it.experiment, it) }
        .groupTuple()
        .map { __, its -> [
            experiment: its.collect { it.experiment }.unique().first(), 
            index: its.collect { it.index }.unique().first(),
            fastp: its.collect { it.fastp }.flatten()
        ] }
        .set { ch_fastp_by_exp_idx }

    emit:
    ch_fastp_by_exp_idx // experiment, index, []fastp
}

workflow join_fastp_bam_spl_by_exp_idx {
    
    take:
    ch_bam_spl_by_exp_idx // exp, idx, []bam, spl
    ch_fastp_by_exp_idx // exp, idx, []fastp

    main:
    
    ch_fastp_sp_by_exp_idx = Channel.empty()

    ch_fastp_by_exp_idx
        .map { it -> tuple(it.experiment, it) }
        .join( 
            ch_bam_spl_by_exp_idx
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_fastp_sp_by_exp_idx }

    emit:
    ch_fastp_sp_by_exp_idx // exp, idx, []fastp, []bam, spl
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/