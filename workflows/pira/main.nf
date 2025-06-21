/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID1 } from '../../subworkflows/local/ID1'
include { ID2 } from '../../subworkflows/local/ID2'
include { ID3_NOVO } from '../../subworkflows/local/ID3'
include { ID3_DENOVO } from '../../subworkflows/local/ID3'
include { ID4_EXPERIMENT } from '../../subworkflows/local/ID4'
include { ID4_CONDITION } from '../../subworkflows/local/ID4'
include { ID5 } from '../../subworkflows/local/ID5'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIRA {    

    take:
    // run, exp, cond
    ch_samples
    ch_index
    ch_bed
    ch_gtf

    main:

    //
    // SUBWORKFLOW: ID1
    //

    ch_fastq = ID1(ch_samples) // run, exp, cond, []fastq

    //
    // SUBWORKFLOW: ID2
    //

    ch_fastp = ID2(ch_fastq) // run, exp, cond, []fastp

    //
    // SUBWORKFLOW: ID3
    //

    ch_fastp_by_exp = group_fastp_by_exp(
        ch_fastp
    ) // exp, []fastp

    ch_novo = ID3_NOVO(
        ch_fastp_by_exp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index] },
    ) // exp, []bam, spl

    ch_fastp_bam_spl_by_exp = join_by_exp(
        ch_fastp_by_exp, 
        ch_novo
    ) // exp, []fastp, spl
    
    ch_denovo = ID3_DENOVO(
        ch_fastp_bam_spl_by_exp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index] },
    ) // exp, []bam

    //
    // SUBWORKFLOW: ID4
    //

    // Exp

    ch_novo
        .map { it -> it + [alignment: "novo"]}
        .set { ch_novo }

    ch_denovo
        .map { it -> it + [alignment: "denovo"]}
        .set { ch_denovo }

    ID4_EXPERIMENT(ch_novo.mix(ch_denovo))

    // Cond

    ch_novo_by_cond = join_by_exp(
        ch_novo,
        ch_samples.map { it -> [experiment: it.experiment, condition: it.condition] }
    )

    ch_novo_by_cond = group_bam_by_cond(
        ch_novo_by_cond
    )

    ch_novo_by_cond
        .map { it -> it + [alignment: "novo"]}
        .set { ch_novo_by_cond }

    ch_denovo_by_cond = join_by_exp(
        ch_denovo,
        ch_samples.map { it -> [experiment: it.experiment, condition: it.condition] }
    )
    
    ch_denovo_by_cond = group_bam_by_cond(
        ch_denovo_by_cond
    )

    ch_denovo_by_cond
        .map { it -> it + [alignment: "denovo"]}
        .set { ch_denovo_by_cond }

    ID4_CONDITION(ch_novo_by_cond.mix(ch_denovo_by_cond))

    //
    // SUBWORKFLOW: ID5
    //

    ID5(
        ch_novo
            .mix(ch_denovo)
            .combine(ch_bed)
            .map {row, bed -> row + [bed: bed.bed] },
    )
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow group_fastp_by_exp {

    take:
    ch_fastp // [exp, []fastp, ...]

    main:

    ch_fastp_by_exp = Channel.empty()
    ch_fastp
        .map { it -> tuple(it.experiment, it) }
        .groupTuple()
        .map { __, its -> [
            experiment: its.collect { it.experiment }.unique().first(), 
            fastp: its.collect { it.fastp }.flatten()
        ] }
        .set { ch_fastp_by_exp }

    emit:
    ch_fastp_by_exp // exp, []fastp
}

workflow group_bam_by_cond {

    take:
    ch_bam // [cond, []bam, ...]

    main:

    ch_out = Channel.empty()
    ch_bam
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it.condition }.unique().first(), 
            bam: its.collect { it.bam }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, []bam
}

workflow join_by_exp {

    take:
    ch_a // exp, ...
    ch_b // exp, ...

    main:
    
    ch_out = Channel.empty()

    ch_a
        .map { it -> tuple(it.experiment, it) }
        .join( 
            ch_b.map {it -> tuple(it.experiment, it)},
            failOnDuplicate: true,
            remainder: false
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_out }

    emit:
    ch_out // exp, ...
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/