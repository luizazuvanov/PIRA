process RMATS_LENGTH {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::gawk=5.3.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.1' :
        'biocontainers/gawk:5.3.1' }"

    input:
    val meta
    path stats

    output:
    tuple val(meta), env('LENGTH')         , emit: stats
    tuple val(meta), path('*.stats.csv')   , emit: average
    tuple val(meta), path('*.merged.stats'), emit: merged
    path("versions.yml")                   , emit: versions

    script:

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # concatenate stats files
    grep -h "^RL" $stats > "$prefix".merged.stats

    # compute the most common read length, truncated to integer
    touch "$prefix".stats.csv
    LENGTH=\$(grep "^RL" "$prefix".merged.stats | sort -nr -k3,3 | head -1 | awk '{print \$2}')
    echo -e "length" >> "$prefix".stats.csv
    echo -e \$LENGTH >> "$prefix".stats.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """

    stub:

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    grep -h "^RL" $stats > "$prefix".merged.stats || true

    touch "$prefix".stats.csv
    LENGTH=30
    echo -e "length" >> "$prefix".stats.csv
    echo -e \$LENGTH >> "$prefix".stats.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo -m 1 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
