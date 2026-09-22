process BED {
    tag "$gtf"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-genepredtobed_ucsc-gtftogenepred:482--c2c4d1698fae524c':
        'community.wave.seqera.io/library/ucsc-genepredtobed_ucsc-gtftogenepred:482--d40a6ae10bc14b92' }"

    input:
    tuple val(meta), path(gtf)

    output:
    tuple val(meta), path('*.bed'), emit: bed
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "$gtf.baseName"
    // WARN: Version information not provided by tool on CLI.
    // Please update this string when bumping container versions.
    def VERSION = '482'

    """
    gtfToGenePred -ignoreGroupsWithoutExons -genePredExt $gtf "$prefix".genepred
    genePredToBed "$prefix".genepred "$prefix".bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtfToGenePred: ${VERSION}
        genePredToBed: ${VERSION}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "$gtf.baseName"
    // WARN: Version information not provided by tool on CLI.
    // Please update this string when bumping container versions.
    def VERSION = '482'

    """
    touch "$prefix".bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtfToGenePred: ${VERSION}
        genePredToBed: ${VERSION}
    END_VERSIONS
    """

}
