process STRANDEDNESS {
    tag "$meta.id"
    label 'process_single'

    // TODO: use Python container
    // TODO: move to modules/local

    input:
    tuple val(meta), path(infer)

    output:
    path("infer.csv"), emit: infer

    script:
    """
    #!/usr/bin/env python3
    import re

    ALIAS: dict[str, str] = {
        "forward": "fr-secondstrand",
        "reverse": "fr-firststrand",
        "": "fr-unstranded"
    }

    PATTERN: dict[str, str] = {
        "++,--": "fr-secondstrand",
        "+-,-+": "fr-firststrand",
        "1++,1--,2+-,2-+": "fr-secondstrand",
        "1+-,1-+,2++,2--": "fr-firststrand"
    }

    fractions: dict[str, float] = {
        "fr-secondstrand": 0.0,
        "fr-firststrand": 0.0
    }

    valid: bool = False
    sequencing: str = "single"

    try:
        with open("$infer", "r") as fp:
            for line in fp:
                line = line.strip().lower()

                if "pairend" in line:
                    sequencing = "paired"
                    continue

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

    alias_key: str = ""
    strandedness: str = ALIAS[alias_key]

    max_fraction: float = 0.0
    for key, value in fractions.items():
        if value > 0.7 and value > max_fraction:
            max_fraction = value
            alias_key = key
            strandedness = ALIAS[alias_key]

    with open("infer.csv", "w") as fp:
        fp.write("sequencing,strandedness,alias\n")
        fp.write(f"{sequencing},{strandedness},{alias}\n")
    """

    stub:
    """
    touch "infer.csv"
    echo -e 'sequencing,strandedness,alias' >> "infer.csv"
    echo -e 'paired,fr-secondstrand,forward' >> "infer.csv"
    """
}
