include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'

workflow ID6_STRINGTIE {

    take:
    ch_input

    main:

    STRANDNESS(
        ch_input.map { it -> tuple([id: it.experiment], it.infer) }
    )

    STRINGTIE_STRINGTIE(
        ch_input.map { it -> tuple(
            [id: it.experiment, alignment: it.alignment, strandedness: STRANDNESS.out.strandness], 
            it.bam
        ) },
        ch_input.map { it -> it.reference }
    )

    // clean

    ch_out = Channel.empty()
    STRINGTIE_STRINGTIE.out.transcript_gtf
        .map { it -> [experiment: it[0].id, alignment: it[0].alignment, gtf: it[1]] }
        .set { ch_out }

    emit:
    ch_out
}

workflow ID6_MERGE {

    take:
    ch_input

    main:

    STRINGTIE_MERGE(
        ch_input.map { it -> it.gtf },
        ch_input.map { it -> it.reference }
    )
}

process STRANDNESS {
    tag "$meta.id"
    label 'process_single'

    // TODO: use Python container
    // TODO: move to modules/local

    input:
    tuple val(meta), path(infer)

    output:
    val(strandness), emit: strandness

    script:
    strandness = ''
    """
    #!/usr/bin/env python3
    import re

    PATTERN: dict[str, str] = {
        "++,--": "forward",
        "+-,-+": "reverse",
        "1++,1--,2+-,2-+": "forward",
        "1+-,1-+,2++,2--": "reverse"
    }

    fractions: dict[str, float] = {
        "forward": 0.0,
        "reverse": 0.0
    }

    valid: bool = False

    try:
        with open("${infer}", "r") as fp:
            for line in fp:
                line = line.strip().lower()
                match = re.search(r'"([^"]*)"', line)
                if not match:
                    continue

                pattern_key = match.group(1)
                direction = PATTERN.get(pattern_key)
                if not direction:
                    continue

                try:
                    explained = float(line.split(":")[-1].strip())
                except ValueError:
                    continue

                fractions[direction] = explained
                valid = True

    except Exception as e:
        raise RuntimeError(f"Failed to parse file: {e}")

    if not valid:
        raise ValueError("Failed to parse file")

    strandnes: str = ""
    max_fraction: float = 0.0
    for key, value in fractions.items():
        if value > 0.7 and value > max_fraction:
            max_fraction = value
            strandnes = key

    print(strandnes)
    """

    stub:
    strandness = ''
    """
    echo 'forward'
    """
}
