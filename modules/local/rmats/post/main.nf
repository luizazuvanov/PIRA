process RMATS_POST {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8b7a2184a4c9e054a13811c086f2d6095637be0f519191db74c35650085f5c20/data' :
        'community.wave.seqera.io/library/rmats:4.3.0--177f3a2035a879e5' }"

    input:
    tuple val(meta), path(gtf)
    path(b1)
    path(b2)
    val(tmp_1)
    val(tmp_2)
    val(readTypes)
    val(readLength)

    output:
    tuple val(meta), path("post/tmp/"), emit: tmp
    path("post/out/")                 , emit: out
    path("versions.yml")              , emit: versions

    script:

    def bams1 = b1.join(',')
    def bams2 = b2.join(',')
    def readType = readTypes.contains('single') ? 'single' : 'paired' // prioritize 'single' if present
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def threads = task.cpus

    """

    mkdir -p post/tmp
    mkdir -p post/out

    echo $bams1 > post/tmp/b1.txt
    echo $bams2 > post/tmp/b2.txt

    cp $tmp_1/*.rmats post/tmp/
    cp $tmp_2/*.rmats post/tmp/

    rmats.py \\
        --task post \\
        --gtf $gtf \\
        --b1 post/tmp/b1.txt \\
        --b2 post/tmp/b2.txt \\
        --od post/out \\
        --tmp post/tmp \\
        -t $readType \\
        --readLength $readLength \\
        --nthread $threads \\
        $args \\
        1> post/tmp/rmats.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(echo \$(rmats.py --version) | sed -e "s/v//g")
    END_VERSIONS
    """

    stub:

    def bams1 = b1.join(',')
    def bams2 = b2.join(',')
    def readType = readTypes.contains('single') ? 'single' : 'paired' // prioritize 'single' if present
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p post/tmp
    mkdir -p post/out

    echo $bams1 > post/tmp/b1.txt
    echo $bams2 > post/tmp/b2.txt

    cp $tmp_1/*.rmats post/tmp/
    cp $tmp_2/*.rmats post/tmp/

    events=(
        SE
        A3SS
        A5SS
        MXE
        RI
    )

    touch post/out/summary.txt
    for event in "\${events[@]}"; do
        touch post/out/\${event}.MATS.JC.txt
        touch post/out/\${event}.MATS.JCEC.txt
        touch post/out/fromGTF.\${event}.txt
        touch post/out/fromGTF.novelJunction.\${event}.txt
        touch post/out/fromGTF.novelSpliceSite.\${event}.txt
        touch post/out/JC.raw.input.\${event}.txt
        touch post/out/JCEC.raw.input.\${event}.txt
        touch post/out/individualCounts.\${event}.txt
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rmats: \$(echo \$(rmats.py --version) | sed -e "s/v//g")
    END_VERSIONS
    """
}
