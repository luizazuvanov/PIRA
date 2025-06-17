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

    print "PIRA"

    // input
    ch_data = channel.fromPath(params.input)
    
    // experiment, run, condition
    ch_samples = Channel.empty()
    
    ch_data
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .unique()
        .set { ch_samples }

    print "ID1"
    // experiment, run, condition, []fastq
    ch_fastq = ID1(ch_samples)

    print "ID2"
    // experiment, run, condition, []fastp
    ch_fastp = ID2(ch_fastq)

    print "ID3"
    // experiment, []fastp
    ch_fastp_by_experiment = Channel.empty()    
    ch_fastp
        .map { it -> tuple(it.experiment, it) }
        .groupTuple()
        .map { __, its -> [
            experiment: its.collect { it.experiment }.unique().first(), 
            fastp: its.collect { it.fastp }.flatten()
        ] }
        .set { ch_fastp_by_experiment }

    // experiment, spl
    ch_spl_by_experiment = ID3(ch_fastp_by_experiment)

    print "ID4"
    // experiment, []fastp, spl
    ch_fastp_spl_by_experiment = Channel.empty() 
    ch_fastp_by_experiment
        .map { it -> tuple(it.experiment, it) }
        .join( 
            ch_spl_by_experiment
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_fastp_spl_by_experiment }

    // experiment, bam
    ch_bam_by_experiment = ID4(ch_fastp_spl_by_experiment)
    ch_bam_by_experiment.view()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
