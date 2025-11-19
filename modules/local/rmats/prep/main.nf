process RMATS_PREP {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8b7a2184a4c9e054a13811c086f2d6095637be0f519191db74c35650085f5c20/data' :
        'community.wave.seqera.io/library/rmats:4.3.0--177f3a2035a879e5' }"

    input:
    tuple val(meta), path(gtf)
    path(b1)
    val(readType)
    val(readLength)
    val(strandedness)

    output:
    tuple val(meta), path("prep/out/"), path("prep/tmp/"), emit: out
    path("versions.yml")                                 , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def threads = task.cpus ?: 10

    """

    ( IFS=,; printf '%s\n' "$b1" ) > b1.txt

    rmats.py \\
        --task prep \\
        --gtf $gtf \\
        --b1 b1.txt \\
        --od prep/out \\
        --tmp prep/tmp \\
        -t $readType \\
        --libType $strandedness \\
        --readLength $readLength \\
        --nthread $threads \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(echo \$(rmats.py --version) | sed -e "s/v//g")
    END_VERSIONS
    """

    stub:

    """

    touch b1.txt
    for bam in $b1; do
        echo \$bam >> b1.txt
    done

    events=(
        SE
        A3SS
        A5SS
        MXE
        RI
    )

    mkdir -p prep/out
    touch prep/out/summary.txt
    for event in "\${events[@]}"; do
        touch prep/out/\${event}.MATS.JC.txt
        touch prep/out/\${event}.MATS.JCEC.txt
        touch prep/out/fromGTF.\${event}.txt
        touch prep/out/fromGTF.novelJunction.\${event}.txt
        touch prep/out/fromGTF.novelSpliceSite.\${event}.txt
        touch prep/out/JC.raw.input.\${event}.txt
        touch prep/out/JCEC.raw.input.\${event}.txt
        touch prep/out/individualCounts.\${event}.txt
    done

    mkdir -p prep/tmp
    touch prep/tmp/pre.rmats
    touch prep/tmp/pre_read_outcomes_by_bam.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(echo \$(rmats.py --version) | sed -e "s/v//g")
    END_VERSIONS
    """
}
