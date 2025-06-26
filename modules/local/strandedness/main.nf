process STRANDEDNESS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8a/8ad257d53c2a2b8810d2b12d4d8e3ea438bc8c4a6be7c39b0354cd7bb8d5c260/data' :
        'community.wave.seqera.io/library/python:3.13.5--18032a8dc5d4b91e' }"

    input:
    tuple val(meta), path(infer)

    output:
    path("infer.csv")   , emit: infer
    path("versions.yml"), emit: versions

    script:
    """
    strandedness.py $infer

    cat <<- END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch "infer.csv"
    echo -e 'sequencing,strandedness,alias' >> "infer.csv"
    echo -e 'paired,fr-secondstrand,forward' >> "infer.csv"

    cat <<- END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
