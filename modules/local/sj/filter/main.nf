process SJ_FILTER {
    tag "$meta.id"
    label 'process_nano'

    conda "conda-forge::gawk=5.3.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.1' :
        'biocontainers/gawk:5.3.1' }"

    input:
    tuple val(meta), path(spl)

    output:
    tuple val(meta), path('*.SJ.out.filter.tab'), emit: spl_junc_tab
    path("versions.yml") , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"

    """

    cat "$prefix".SJ.out.tab | awk '(\$5>1 && \$6==0 && \$7 > 2)' | cut -f1-6 | sort | uniq > "$prefix".SJ.out.filter.tab

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "$meta.id"
    """

    touch "$prefix".SJ.out.filter.tab

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo -m 1 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
