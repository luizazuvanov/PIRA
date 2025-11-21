process RMATS_STRAND {
    tag "$meta.id"
    label 'process_nano'

    conda "conda-forge::gawk=5.3.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.1' :
        'biocontainers/gawk:5.3.1' }"

    input:
    val meta
    val infer

    output:
    tuple val(meta), env('SEQUE'), env('STRAN'), env('ALIAS'), emit: infer
    tuple val(meta), path('*.infer.csv')                     , emit: merged
    path("versions.yml")                                     , emit: versions

    script:

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # concatenate infer files
    touch "$prefix".merged.infer
    files=\$(echo "$infer" | tr -d '[],')
    for file in \$files; do
        cat \$file >> "$prefix".merged.infer
    done

    # fetch first two rows
    awk 'NR<=2' "$prefix".merged.infer > "$prefix".infer.csv
    SEQUE=\$(awk -F',' 'NR==2 { print \$4 }')
    STRAN=\$(awk -F',' 'NR==2 { print \$5 }')
    ALIAS=\$(awk -F',' 'NR==2 { print \$6 }')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """

    stub:

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    SEQUE="paired"
    STRAN="fr-secondstrand"
    ALIAS="forward"

    touch "$prefix".infer.csv
    echo -e "sequencing,strandedness,alias" >> "$prefix".infer.csv
    echo -e "\$SEQUE,\$STRAN,\$ALIAS" >> "$prefix".infer.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo -m 1 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
