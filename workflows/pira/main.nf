/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID1               } from '../../subworkflows/local/ID1/main'
include { ID2               } from '../../subworkflows/local/ID2/main'
include { ID3_NOVO          } from '../../subworkflows/local/ID3/main'
include { ID3_DENOVO        } from '../../subworkflows/local/ID3/main'
include { ID4_EXPERIMENT    } from '../../subworkflows/local/ID4/main'
include { ID4_CONDITION     } from '../../subworkflows/local/ID4/main'
include { ID5               } from '../../subworkflows/local/ID5/main'
include { ID6_STRINGTIE     } from '../../subworkflows/local/ID6/main'
include { ID6_MERGE         } from '../../subworkflows/local/ID6/main'
include { ID7 as ID7_NOVO   } from '../../subworkflows/local/ID7/main'
include { ID7 as ID7_DENOVO } from '../../subworkflows/local/ID7/main'

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
    ) // cond, []bam

    ch_novo_by_cond
        .map { it -> it + [alignment: "novo"]}
        .set { ch_novo_by_cond }

    ch_denovo_by_cond = join_by_exp(
        ch_denovo,
        ch_samples.map { it -> [experiment: it.experiment, condition: it.condition] }
    )
    
    ch_denovo_by_cond = group_bam_by_cond(
        ch_denovo_by_cond
    ) // cond, []bam

    ch_denovo_by_cond
        .map { it -> it + [alignment: "denovo"]}
        .set { ch_denovo_by_cond }

    ID4_CONDITION(ch_novo_by_cond.mix(ch_denovo_by_cond))

    //
    // SUBWORKFLOW: ID5
    //

    ch_mixed = ID5(
        ch_novo
            .mix(ch_denovo)
            .combine(ch_bed)
            .map {row, bed -> row + [bed: bed.bed] },
    ) // exp, alignment, infer

    //
    // SUBWORKFLOW: ID6
    //

    // Exp

    ch_denovo = join_by_exp(
        ch_denovo,
        ch_mixed.filter {it -> it.alignment == "denovo" }
    ) // exp, []bam, alignment, infer

    ch_denovo_gtf = ID6_STRINGTIE(
        ch_denovo
            .combine(ch_gtf)
            .map {row, gtf -> row + [reference: gtf.gtf] },
    ) // exp, alignment, gtf

    ch_denovo_gtf = group_gtf_by_align(
        ch_denovo_gtf
    ) // align, []gtf

    // Align

    ch_denovo_gtf = ID6_MERGE(
        ch_denovo_gtf
            .combine(ch_gtf)
            .map {row, gtf -> row + [reference: gtf.gtf] },
    ) // align, gtf

    //
    // SUBWORKFLOW: ID7
    //

    ch_pairs_cond = compute_pairs_by_cond(
        ch_samples.map { it -> [condition: it.condition] }
    ) // cond_1, cond_2

    // Novo

    ch_novo_pairs_cond = combine_by_cond(
        ch_pairs_cond.map { it -> [condition: it.cond_1] + it},
        ch_novo_by_cond
    )

    ch_novo_pairs_cond = ch_novo_pairs_cond.map { it -> 
        [
            cond_1: it.cond_1, 
            cond_2: it.cond_2, 
            alignment: it.alignment, 
            bam_1: it.bam
        ] 
    }

    ch_novo_pairs_cond = combine_by_cond(
        ch_novo_pairs_cond.map { it -> [condition: it.cond_2] + it},
        ch_novo_by_cond
    )

    ch_novo_pairs_cond = ch_novo_pairs_cond.map { it -> 
        [
            cond_1: it.cond_1, 
            cond_2: it.cond_2, 
            alignment: it.alignment, 
            bam_1: it.bam_1,
            bam_2: it.bam
        ] 
    } // cond_1, cond_2, alignment, []bam_1, []bam_2

    ID7_NOVO(
        ch_novo_pairs_cond
            .combine(ch_gtf)
            .map {row, gtf -> row + [gtf: gtf.gtf] }
            .combine(
                ch_denovo
                    .map { it -> [infer: it.infer] }
                    .distinct()
            )
            .map { row, infer -> row + [infer: infer.infer] }
    )

    // Denovo

    ch_denovo_pairs_cond = combine_by_cond(
        ch_pairs_cond.map { it -> [condition: it.cond_1] + it},
        ch_denovo_by_cond
    )

    ch_denovo_pairs_cond = ch_denovo_pairs_cond.map { it -> 
        [
            cond_1: it.cond_1, 
            cond_2: it.cond_2, 
            alignment: it.alignment, 
            bam_1: it.bam
        ] 
    }

    ch_denovo_pairs_cond = combine_by_cond(
        ch_denovo_pairs_cond.map { it -> [condition: it.cond_2] + it},
        ch_denovo_by_cond
    )

    ch_denovo_pairs_cond = ch_denovo_pairs_cond.map { it -> 
        [
            cond_1: it.cond_1, 
            cond_2: it.cond_2, 
            alignment: it.alignment, 
            bam_1: it.bam_1,
            bam_2: it.bam
        ] 
    } // cond_1, cond_2, alignment, []bam_1, []bam_2

    ID7_DENOVO(
        ch_denovo_pairs_cond
            .combine(ch_denovo_gtf)
            .map {row, gtf -> row + [gtf: gtf.gtf] }
            .combine(
                ch_denovo
                    .map { it -> [infer: it.infer] }
                    .distinct()
            )
            .map { row, infer -> row + [infer: infer.infer] }
    )
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow group_gtf_by_align {

    take:
    ch_gtf // [align, []gtf, ...]

    main:

    ch_gtf_by_align = Channel.empty()
    ch_gtf
        .map { it -> tuple(it.alignment, it) }
        .groupTuple()
        .map { __, its -> [
            alignment: its.collect { it.alignment }.unique().first(), 
            gtf: its.collect { it.gtf }.flatten()
        ] }
        .set { ch_gtf_by_align }

    emit:
    ch_gtf_by_align // align, []gtf
}

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

workflow combine_by_cond {

    take:
    ch_a // cond, ...
    ch_b // cond, ...

    main:
    
    ch_out = Channel.empty()

    ch_a
        .map { it -> tuple(it.condition, it) }
        .combine( 
            ch_b.map {it -> tuple(it.condition, it)},
            by: 0
        )
        .map { __, a, b -> a + b } // drop join key
        .set { ch_out }

    emit:
    ch_out // cond, ...
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

workflow compute_pairs_by_cond {

    take:
    ch_input // cond, ...

    main:

    ch_out = Channel.empty()

    ch_input
        .map { it -> it.condition }
        .distinct()
        .collect()
        .flatMap { it ->
            def pairs = []
            for (int i = 0; i < it.size(); i++) { 
                for (int j = i + 1; j < it.size(); j++) {
                    pairs << [cond_1: it[i], cond_2: it[j]]
                }
            }
            return pairs
        }
        .set { ch_out }

    emit:
    ch_out // cond_1, cond_2
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/