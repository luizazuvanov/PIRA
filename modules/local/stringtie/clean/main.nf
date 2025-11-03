process STRINGTIE_CLEAN {
    tag "$meta.id"
    label 'process_nano'

    conda "conda-forge::gawk=5.3.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.1' :
        'biocontainers/gawk:5.3.1' }"

    input:
    tuple val(meta), path(reference)

    output:
    tuple val(meta), path('*.gtf'), emit: reference_clean
    path("versions.yml") , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"
    
    """

    awk -F"\t" '\$3 != "gene"' "$reference" > "$reference".clean.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "$meta.id"
    """

    touch "$reference".clean.gtf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo -m 1 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}