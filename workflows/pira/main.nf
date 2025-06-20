/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID1 } from '../../subworkflows/local/ID1'
include { ID2 } from '../../subworkflows/local/ID2'
include { ID3A } from '../../subworkflows/local/ID3'
include { ID3B } from '../../subworkflows/local/ID3'

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

    println "ID3A"
    ch_fastp_by_exp = group_fastp_by_exp(ch_fastp) // exp, idx, []fastp
    ch_novo = ID3A(ch_fastp_by_exp) // exp, idx, []bam, spl

    println "ID3B"
    ch_fastp_bam_spl_by_exp = join_fastp_bam_spl_by_exp(ch_fastp_by_exp, ch_novo) // exp, idx, []fastp, spl
    ch_denovo = ID3B(ch_fastp_bam_spl_by_exp) // exp, idx, []bam, spl

    //
    // SUBWORKFLOW: ID4
    //



}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow group_fastp_by_exp {

    take:
    ch_fastp // run, experiment, condition, index

    main:

    ch_fastp_by_exp = Channel.empty()
    ch_fastp
        .map { it -> tuple(it.experiment, it) }
        .groupTuple()
        .map { __, its -> [
            experiment: its.collect { it.experiment }.unique().first(), 
            index: its.collect { it.index }.unique().first(),
            fastp: its.collect { it.fastp }.flatten()
        ] }
        .set { ch_fastp_by_exp }

    emit:
    ch_fastp_by_exp // experiment, index, []fastp
}

workflow join_fastp_bam_spl_by_exp {
    
    take:
    ch_bam_spl_by_exp // exp, idx, []bam, spl
    ch_fastp_by_exp // exp, idx, []fastp

    main:
    
    ch_fastp_sp_by_exp = Channel.empty()

    ch_fastp_by_exp
        .map { it -> tuple(it.experiment, it) }
        .join( 
            ch_bam_spl_by_exp
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_fastp_sp_by_exp }

    emit:
    ch_fastp_sp_by_exp // exp, idx, []fastp, []bam, spl
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/