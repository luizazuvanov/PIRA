/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID1                                     } from '../../subworkflows/local/ID1/main'
include { ID2                                     } from '../../subworkflows/local/ID2/main'
include { ID3_INDEX                               } from '../../subworkflows/local/ID3/main'
include { ID3_NOVO                                } from '../../subworkflows/local/ID3/main'
include { ID3_DENOVO                              } from '../../subworkflows/local/ID3/main'
include { ID4_EXPERIMENT                          } from '../../subworkflows/local/ID4/main'
include { ID5_BED                                 } from '../../subworkflows/local/ID5/main'
include { ID5_RSEQC                               } from '../../subworkflows/local/ID5/main'
include { ID5_STRANDEDNESS                        } from '../../subworkflows/local/ID5/main'
include { ID6_CLEAN                               } from '../../subworkflows/local/ID6/main'
include { ID6_STRINGTIE                           } from '../../subworkflows/local/ID6/main'
include { ID6_MERGE                               } from '../../subworkflows/local/ID6/main'
include { ID7_RMATS_LENGTH                        } from '../../subworkflows/local/ID7/main'
include { ID7_RMATS_PREP as ID7_RMATS_PREP_NOVO   } from '../../subworkflows/local/ID7/main'
include { ID7_RMATS_POST as ID7_RMATS_POST_NOVO   } from '../../subworkflows/local/ID7/main'
include { ID7_RMATS_PREP as ID7_RMATS_PREP_DENOVO } from '../../subworkflows/local/ID7/main'
include { ID7_RMATS_POST as ID7_RMATS_POST_DENOVO } from '../../subworkflows/local/ID7/main'

include { softwareVersionsToYAML } from '../../subworkflows/nf-core/utils_nfcore_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIRA {

    take:
    ch_samples
    ch_fasta
    ch_gtf

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: ID1
    // ch_fastq = run, exp, cond, []fastq
    //

    if (!params.with_fastq) {
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

    ID3_INDEX(ch_fasta, ch_gtf)
    ch_index = ID3_INDEX.out.data
    ch_versions = ch_versions.mix(ID3_INDEX.out.versions)

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
    // ch_strandedness = exp, alignment, cond, sequencing, strandedness, alias
    //

    ID5_BED(ch_gtf)
    ch_bed = ID5_BED.out.data
    ch_versions = ch_versions.mix(ID5_BED.out.versions)

    ID5_RSEQC(
        ch_bam
            .combine(ch_bed)
            .map {row, bed -> row + [bed: bed.bed] },
    )
    ch_versions = ch_versions.mix(ID5_RSEQC.out.versions)

    ID5_STRANDEDNESS(ID5_RSEQC.out.data)
    ch_strandedness = ID5_STRANDEDNESS.out.data
    ch_versions = ch_versions.mix(ID5_STRANDEDNESS.out.versions)

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
        ch_strandedness
            .filter {it -> it.alignment == "denovo"}
            .map { it -> [experiment: it.experiment, strandedness: it.strandedness]}
    )

    ID6_STRINGTIE(
        ch_denovo
            .combine(ch_gtf_clean)
            .map {row, gtf -> row + [reference: gtf.reference] },
    )

    ch_versions = ch_versions.mix(ID6_STRINGTIE.out.versions)

    //
    // SUBWORKFLOW: ID6 MERGE
    // ch_gtf_merged = alignment, gtf
    //

    ch_gtf_denovo = group_gtf_by_align(
        ID6_STRINGTIE.out.data
    )

    ID6_MERGE(
        ch_gtf_denovo
            .combine(ch_gtf_clean)
            .map {row, gtf -> row + [reference: gtf.reference] },
    )

    ch_gtf_denovo = ID6_MERGE.out.data
    ch_versions = ch_versions.mix(ID6_MERGE.out.versions)

    //
    // SUBWORKFLOW: ID7
    //

    ch_stats_by_align = group_stats_by_align(ch_stats)

    ID7_RMATS_LENGTH(
        ch_stats_by_align
    )

    ch_length = ID7_RMATS_LENGTH.out.data
    ch_versions = ch_versions.mix(ID7_RMATS_LENGTH.out.versions)

    // NOVO

    // assumes alias, sequencing and strandedness are unique per condition and alignment
    ch_novo_strandedness = reduce_strandedness_by_cond_align(
        ch_strandedness
            .filter { it -> it.alignment == "novo" }
    )

    ch_novo_bam = group_bam_by_cond_align(
        ch_bam
            .filter { it -> it.alignment == "novo" }
            .map { it -> [condition: it.condition, alignment: it.alignment, bam: it.bam] }
    )

    ch_novo_pre = combine_by_cond(
        ch_novo_strandedness,
        ch_novo_bam
    )

    ID7_RMATS_PREP_NOVO(
        ch_novo_pre
            .combine(
                ch_length
                    .filter { it -> it.alignment == "novo" }
                    .map { it -> [ length: it.length ] }
            )
            .map { row, length -> row + [length: length.length] }
            .combine(ch_gtf)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_novo_rmats_prep = ID7_RMATS_PREP_NOVO.out.data
    ch_versions = ch_versions.mix(ID7_RMATS_PREP_NOVO.out.versions)

    ch_novo_rmats_post = compute_pairs_by_cond(
        ch_novo_rmats_prep
    )

    ID7_RMATS_POST_NOVO(
        ch_novo_rmats_post
            .combine(ch_gtf)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_versions = ch_versions.mix(ID7_RMATS_POST_NOVO.out.versions)

    // DENOVO

    // assumes alias, sequencing and strandedness are unique per condition and alignment
    ch_denovo_strandedness = reduce_strandedness_by_cond_align(
        ch_strandedness
            .filter { it -> it.alignment == "denovo" }
    )

    ch_denovo_bam = group_bam_by_cond_align(
        ch_bam
            .filter { it -> it.alignment == "denovo" }
            .map { it -> [condition: it.condition, alignment: it.alignment, bam: it.bam] }
    )

    ch_denovo_pre = combine_by_cond(
        ch_denovo_strandedness,
        ch_denovo_bam
    )

    ID7_RMATS_PREP_DENOVO(
        ch_denovo_pre
            .combine(
                ch_length
                    .filter { it -> it.alignment == "denovo" }
                    .map { it -> [ length: it.length ] }
            )
            .map { row, length -> row + [length: length.length] }
            .combine(ch_gtf_denovo)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_denovo_rmats_prep = ID7_RMATS_PREP_DENOVO.out.data
    ch_versions = ch_versions.mix(ID7_RMATS_PREP_DENOVO.out.versions)

    ch_denovo_rmats_post = compute_pairs_by_cond(
        ch_denovo_rmats_prep
    )

    ID7_RMATS_POST_DENOVO(
        ch_denovo_rmats_post
            .combine(ch_gtf_denovo)
            .map { row, gtf -> row + [gtf: gtf.gtf] }
    )
    ch_versions = ch_versions.mix(ID7_RMATS_POST_DENOVO.out.versions)

    //
    // WRAP UP
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

workflow group_stats_by_align {

    take:
    ch_stats // [align, stats, ...]

    main:

    ch_out = Channel.empty()
    ch_stats
        .map { it -> tuple(it.alignment, it) }
        .groupTuple()
        .map { __, its -> [
            alignment: its.collect { it.alignment }.unique().first(),
            stats: its.collect { it.stats }.flatten()
        ] }
        .set { ch_out }

    emit:
    ch_out // align, []stats
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
    ch_input // [cond, ...], [cond, ...]

    main:

    ch_out = Channel.empty()

    ch_input
        .collect()
        .flatMap { items ->
            def combinations = []
            for (int i = 0; i < items.size(); i++) {
                for (int j = i + 1; j < items.size(); j++) {
                    def cond_1 = items[i]
                    def cond_2 = items[j]
                    def combined = [
                        condition: "${cond_1.condition}_vs_${cond_2.condition}",
                        bam_1: cond_1.bam,
                        bam_2: cond_2.bam,
                        tmp_1: cond_1.tmp,
                        tmp_2: cond_2.tmp,
                        length: cond_1.length,
                        alignment: cond_1.alignment, // both have same alignment
                        sequencing: [cond_1.sequencing, cond_2.sequencing],
                    ]
                    combinations.add(combined)
                }
            }
            return combinations
        }
        .set { ch_out }

    emit:
    ch_out // [cond1_vs_cond2, ...]
}

workflow reduce_strandedness_by_cond_align {

    take:
    ch_strandedness // [cond, align, alias, strandedness, sequencing]

    main:

    ch_out = Channel.empty()
    ch_strandedness
        .map { it -> tuple(it.condition, it) }
        .groupTuple()
        .map { __, its -> [
            condition: its.collect { it.condition }.unique().first(),
            alignment: its.collect { it.alignment }.unique().first(),
            alias: its.collect { it.alias }.first(),
            sequencing: its.collect { it.sequencing }.first(),
            strandedness: its.collect { it.strandedness }.first()
        ] }
        .set { ch_out }

    emit:
    ch_out // cond, align, alias, strandedness, sequencing
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
