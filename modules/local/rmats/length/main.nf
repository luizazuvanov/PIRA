process RMATS_LENGTH {
    tag "$meta.id"
    label 'process_nano'

    conda "conda-forge::gawk=5.3.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.1' :
        'biocontainers/gawk:5.3.1' }"

    input:
    val meta
    val stats

    output:
    tuple val(meta), env('LENGTH')      , emit: stats
    tuple val(meta), path('*.stats.csv'), emit: merged
    path("versions.yml")                , emit: versions

    script:

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # concatenate stats files
    touch "$prefix".merged.stats
    files=\$(echo "$stats" | tr -d '[],')
    for file in \$files; do
        grep "^RL" \$file >> "$prefix".merged.stats
    done

    # compute the average read length, truncated to integer
    touch "$prefix".stats.csv
    LENGTH=\$(grep "^RL" "$prefix".merged.stats | awk '{sum += \$3} END {printf "%.0f\\n", sum/NR}')
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
