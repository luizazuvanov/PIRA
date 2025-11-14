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
include { ID5               } from '../../subworkflows/local/ID5/main'
include { ID6_CLEAN         } from '../../subworkflows/local/ID6/main'
include { ID6_STRINGTIE     } from '../../subworkflows/local/ID6/main'
include { ID6_MERGE         } from '../../subworkflows/local/ID6/main'
include { ID7 as ID7_NOVO   } from '../../subworkflows/local/ID7/main'
include { ID7 as ID7_DENOVO } from '../../subworkflows/local/ID7/main'

include { softwareVersionsToYAML } from '../../subworkflows/nf-core/utils_nfcore_pipeline'

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

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: ID1
    // ch_fastq = run, exp, cond, []fastq
    //

    if (params.download) {
        ID1(ch_samples)
        ch_fastq = ID1.out.data
        ch_versions = ch_versions.mix(ID1.out.versions)
    } else {
        ch_fastq = ch_samples.map { row -> row + [ fastq: [file(row.fastq_1), file(row.fastq_2)] ] }
    }

    //
    // SUBWORKFLOW: ID2
    // ch_fastp = run, exp, cond, []fastp
    //

    ID2(ch_fastq)
    ch_fastp = ID2.out.data
    ch_versions = ch_versions.mix(ID2.out.versions)

    //
    // SUBWORKFLOW: ID3
    // ch_bam = exp, alignment, cond, bam
    //

    ID3_NOVO(
        ch_fastp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index, alignment: "novo"] },
    )

    ch_novo = ID3_NOVO.out.data
    ch_versions = ch_versions.mix(ID3_NOVO.out.versions)

    ch_novo_by_exp = join_by_exp(
        ch_fastp,
        ch_novo
    )

    ID3_DENOVO(
        ch_novo_by_exp
            .combine(ch_index)
            .map {row, index -> row + [index: index.index, alignment: "denovo"] },
    )

    ch_denovo = ID3_DENOVO.out.data
    ch_versions = ch_versions.mix(ID3_DENOVO.out.versions)

    ch_bam = Channel.empty()
    ch_novo
        .mix(ch_denovo)
        .map { it -> [experiment: it.experiment, alignment: it.alignment, condition: it.condition, bam: it.bam] }
        .set { ch_bam }

    //
    // SUBWORKFLOW: ID4
    // ch_stats = exp, alignment, cond, stats
    //

    ID4_EXPERIMENT(ch_bam)
    ch_stats = ID4_EXPERIMENT.out.data

    //
    // SUBWORKFLOW: ID5
    // ch_infer = exp, alignment, cond, infer
    //

    ID5(
        ch_bam
            .combine(ch_bed)
            .map {row, bed -> row + [bed: bed.bed] },
    )

    ch_infer = ID5.out.data
    ch_versions = ch_versions.mix(ID5.out.versions)

    //
    // SUBWORKFLOW: ID6 CLEAN
    // ch_gtf_clean = reference
    //

    ID6_CLEAN(ch_gtf)
    ch_gtf_clean = ID6_CLEAN.out.data
    ch_versions = ch_versions.mix(ID6_CLEAN.out.versions)

    //
    // SUBWORKFLOW: ID6 STRINGTIE
    // ch_denovo = exp, alignment, cond, gtf
    //

    ch_denovo = join_by_exp(
        ch_bam
            .filter {it -> it.alignment == "denovo"},
        ch_infer
            .filter {it -> it.alignment == "denovo"}
            .map { it -> [experiment: it.experiment, infer: it.infer]}
    )

    ID6_STRINGTIE(
        ch_denovo
            .combine(ch_gtf_clean)
            .map {row, gtf -> row + [reference: gtf.reference] },
    )

    ch_denovo = ID6_STRINGTIE.out.data
    ch_versions = ch_versions.mix(ID6_STRINGTIE.out.versions)

    //
    // SUBWORKFLOW: ID6 MERGE
    // ch_gtf_merged = alignment, gtf
    //

    ch_denovo = group_gtf_by_align(
        ch_denovo
    )

    ID6_MERGE(
        ch_denovo
            .combine(ch_gtf_clean)
            .map {row, gtf -> row + [reference: gtf.reference] },
    )

    ch_gtf_denovo = ID6_MERGE.out.data
    ch_versions = ch_versions.mix(ID6_MERGE.out.versions)

    //
    // SUBWORKFLOW: ID7
    //

    ch_pairs_cond = compute_pairs_by_cond(
        ch_samples.map { it -> [condition: it.condition] }
    ) // cond_1, cond_2

    // Novo

    ch_bam_novo = group_bam_by_cond_align(
        ch_bam
            .filter {it -> it.alignment == "novo"}
    )

    ch_novo_pairs_cond = combine_by_cond(
        ch_pairs_cond.map { it -> [condition: it.cond_1] + it},
        ch_bam_novo
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
        ch_bam_novo
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
                ch_infer
                    .filter { it -> it.alignment == "novo" }
                    .map { it -> [infer: it.infer] }
                    .first()
            )
            .map { row, infer -> row + [infer: infer.infer] }
            .combine(
                ch_stats
                    .filter { it -> it.alignment == "novo" }
                    .map { it -> [stats: it.stats] }
                    .first()
            )
            .map { row, stats -> row + [stats: stats.stats] }
    )
    ch_versions = ch_versions.mix(ID7_NOVO.out.versions)

    // Denovo

    ch_bam_denovo = group_bam_by_cond_align(
        ch_bam
            .filter {it -> it.alignment == "denovo"}
    )

    ch_denovo_pairs_cond = combine_by_cond(
        ch_pairs_cond.map { it -> [condition: it.cond_1] + it},
        ch_bam_denovo
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
        ch_bam_denovo
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
            .combine(ch_gtf_denovo)
            .map {row, gtf -> row + [gtf: gtf.gtf] }
            .combine(
                ch_infer
                    .filter { it -> it.alignment == "denovo" }
                    .map { it -> [infer: it.infer] }
                    .first()
            )
            .map { row, infer -> row + [infer: infer.infer] }
            .combine(
                ch_stats
                    .filter { it -> it.alignment == "denovo" }
                    .map { it -> [stats: it.stats] }
                    .first()
            )
            .map { row, stats -> row + [stats: stats.stats] }
    )
    ch_versions = ch_versions.mix(ID7_DENOVO.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pira_software_versions.yml',
            sort: true,
            newLine: true
        )

    emit:
    multiqc_report = Channel.empty()
    versions = ch_versions
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

workflow group_bam_by_cond_align {

    take:
    ch_bam // [cond, align, []bam, ...]

    main:

    ch_out = Channel.empty()
    ch_bam
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it.condition }.unique().first(),
            alignment: its.collect { it.alignment }.unique().first(),
            bam: its.collect { it.bam }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, align, []bam
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
