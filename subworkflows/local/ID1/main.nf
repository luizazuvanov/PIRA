include { SRATOOLS_PREFETCH           } from '../../../modules/nf-core/sratools/prefetch/main.nf'
include { SRATOOLS_FASTERQDUMP        } from '../../../modules/nf-core/sratools/fasterqdump/main.nf'
include { CUSTOM_SRATOOLSNCBISETTINGS } from '../../../modules/nf-core/custom/sratoolsncbisettings/main'

process step {
    
    publishDir path: "${params.outdir}/sequence/raw/fq/", mode: 'move', pattern: "${meta.experiment}/*.fastq.gz"

    input:
    tuple val(meta), path(reads)
    
    output:
    path "${meta.experiment}/*.fastq.gz"

    script:
    """
    mkdir -p ${meta.experiment}
    for read in ${reads}; do cp \${read} ${meta.experiment}/\${read}; done
    """
}

workflow ID1 {

    take:
    ch_samples

    main:

    samples = ch_samples.map { it -> tuple([id: it[0], experiment: it[1]], it[0]) }

    CUSTOM_SRATOOLSNCBISETTINGS(
        samples
    )

    SRATOOLS_PREFETCH(
        samples, 
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings, 
        []
    )

    SRATOOLS_FASTERQDUMP(
        SRATOOLS_PREFETCH.out.sra, 
        CUSTOM_SRATOOLSNCBISETTINGS.out.ncbi_settings, 
        []
    )

    emit:
    reads = SRATOOLS_FASTERQDUMP.out.reads
}