#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/pira
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/pira
    Website: https://nf-co.re/pira
    Slack  : https://nfcore.slack.com/channels/pira
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PIRA                    } from './workflows/pira'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_pira_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_pira_pipeline'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline
//
workflow NFCORE_PIRA {

    main:

    ch_index_optional = Channel.empty()
    ch_samples = Channel.empty()
    ch_fasta = Channel.empty()
    ch_gtf = Channel.empty()

    Channel
        .fromPath(params.input, type: "file")
        .map { it -> file(it) }
        .splitCsv( header: true, strip: true )
        .unique()
        .map { it -> it + [single_end: it.single_end.toBoolean()] }
        .set { ch_samples }

    Channel
        .fromPath(params.fasta, type: "file")
        .map { it -> [fasta: it]}
        .set { ch_fasta }

    Channel
        .fromPath(params.gtf, type: "file")
        .map { it -> [gtf: it]}
        .set { ch_gtf }

    def with_index = !(params.index == null || params.index.trim() == "")
    if (with_index) {
        Channel
            .fromPath(params.index, type: "dir")
            .map { it -> [index: it]}
            .set { ch_index_optional }
    }

    //
    // WORKFLOW: Run workflows/pira pipeline
    //
    PIRA (ch_samples, ch_fasta, ch_gtf, ch_index_optional)

    emit:
    multiqc_report = PIRA.out.multiqc_report
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input,
        params.help,
        params.help_full,
        params.show_hidden
    )

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_PIRA ()

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        NFCORE_PIRA.out.multiqc_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
