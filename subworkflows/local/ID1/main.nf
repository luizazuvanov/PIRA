process step {
    
    publishDir path: "${params.outdir}/sequence/raw/fq/${experiment}", mode: 'copy', pattern: "${run}.txt"

    input:
    tuple val(run), val(experiment), val(condition)

    output:
    path "${run}.txt"

    script:
    """
    echo "${run} * ${experiment} * ${condition}" > "${run}.txt"
    """
}

workflow ID1 {

    take:
    ch_samples

    main:
    step(ch_samples)
}