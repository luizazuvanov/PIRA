process RMATS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8b7a2184a4c9e054a13811c086f2d6095637be0f519191db74c35650085f5c20/data' :
        'community.wave.seqera.io/library/rmats:4.3.0--177f3a2035a879e5' }"

    input:
    tuple val(meta)
    path(gtf)
    path(b1)
    path(b2)
    val(read_type)
    val(read_length)
    val(strandedness)

    output:
    path("${meta.id}/out/"), emit: out
    path("${meta.id}/tmp/"), emit: tmp
    path("versions.yml")   , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def threads = task.cpus ?: 10

    read_type = read_type ?: 'paired' // {paired,single}
    read_length = read_length ?: 150 
    strandedness = strandedness ?: 'fr-unstranded' // {fr-unstranded,fr-firststrand,fr-secondstrand}
    
    """
    rmats.py \\
        --gtf $gtf \\
        --b1 $b1 \\ 
        --b2 $b2 \\
        --od $prefix/out \\
        --tmp $prefix/tmp \\
        --t $read_type \\
        --libType $strandedness \\
        --readLength $read_length \\
        --nthread $threads \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(echo \$(rmats.py --version) | sed -e "s/v//g")
    END_VERSIONS
    """

    stub:

    """
    events=(
        SE
        A3SS
        A5SS
        MXE
        RI
    )

    mkdir -p ${meta.id}/out
    touch ${meta.id}/out/summary.txt
    for event in "\${events[@]}"; do
        touch ${meta.id}/out/\${event}.MATS.JC.txt
        touch ${meta.id}/out/\${event}.MATS.JCEC.txt
        touch ${meta.id}/out/fromGTF.\${event}.txt
        touch ${meta.id}/out/fromGTF.novelJunction.\${event}.txt
        touch ${meta.id}/out/fromGTF.novelSpliceSite.\${event}.txt
        touch ${meta.id}/out/JC.raw.input.\${event}.txt
        touch ${meta.id}/out/JCEC.raw.input.\${event}.txt
        touch ${meta.id}/out/individualCounts.\${event}.txt
    done

    mkdir -p ${meta.id}/tmp
    touch ${meta.id}/tmp/pre.rmats
    touch ${meta.id}/tmp/pre_read_outcomes_by_bam.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(echo \$(rmats.py --version) | sed -e "s/v//g")
    END_VERSIONS
    """
}