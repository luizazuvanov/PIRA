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

    ch_input = channel.fromPath(params.input, type: "file")
    ch_index = channel.fromPath(params.index, type: "dir")
    ch_samples = Channel.empty() // experiment, run, condition
    
    ch_input
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .unique()
        .combine(ch_index)
        .map { row, index -> row + [index: index]}
        .set { ch_samples }

    print "ID1"
    ch_fastq = ID1(ch_samples) // experiment, run, condition, index, []fastq

    print "ID2"
    ch_fastp = ID2(ch_fastq) // experiment, run, condition, index, []fastp

    print "ID3"
    ch_fastp_by_experiment = Channel.empty() // experiment, index, []fastp 
    ch_fastp
        .map { it -> tuple(it.experiment, it) }
        .groupTuple()
        .map { __, its -> [
            experiment: its.collect { it.experiment }.unique().first(), 
            index: its.collect { it.index }.unique().first(),
            fastp: its.collect { it.fastp }.flatten()
        ] }
        .set { ch_fastp_by_experiment }

    ch_fastp_by_experiment.view()

    ch_spl_by_experiment = ID3(ch_fastp_by_experiment) // experiment, index, spl

    print "ID4"
    ch_fastp_spl_by_experiment = Channel.empty() // experiment, index, []fastp, spl
    ch_fastp_by_experiment
        .map { it -> tuple(it.experiment, it) }
        .join( 
            ch_spl_by_experiment
            .map {it -> tuple(it.experiment, it)}
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_fastp_spl_by_experiment }

    ch_bam_by_experiment = ID4(ch_fastp_spl_by_experiment) // experiment, index, bam
    ch_bam_by_experiment.view()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
