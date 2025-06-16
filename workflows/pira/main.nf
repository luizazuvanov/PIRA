/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID1 } from '../../subworkflows/local/ID1'
include { ID2 } from '../../subworkflows/local/ID2'
include { ID3 } from '../../subworkflows/local/ID3'

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
    ch_samples = ID1(ch_samples)

    print "ID2"
    // experiment, run, condition, []fastp
    ch_samples = ID2(ch_samples)

    print "ID3"
    // experiment, []fastp
    ch_samples_by_experiment = Channel.empty()    
    ch_samples
        .map { it -> tuple(it.experiment, it) }
        .groupTuple()
        .map { __, its -> [
            experiment: its.collect { it.experiment }.unique().first(), 
            out: its.collect { it.out }.flatten()
        ] }
        .set { ch_samples_by_experiment }

    // experiment, bam  
    ch_samples_by_experiment = ID3(ch_samples_by_experiment)

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
