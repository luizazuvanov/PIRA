#!/usr/bin/env python3

import re
import sys

from typing import Union

ALIAS: dict[str, str] = {
    "fr-secondstrand": "forward",
    "fr-firststrand": "reverse",
    "fr-unstranded": "",
}

PATTERN: dict[str, str] = {
    "++,--": "fr-secondstrand",
    "+-,-+": "fr-firststrand",
    "1++,1--,2+-,2-+": "fr-secondstrand",
    "1+-,1-+,2++,2--": "fr-firststrand",
}


def parse(filepath: str) -> Union[dict[str: str], Exception]:

    fractions: dict[str, float] = {"fr-secondstrand": 0.0, "fr-firststrand": 0.0}

    valid: bool = False
    sequencing: str = "single"

    try:
        with open(filepath, "r") as fp:
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

    alias_key: str = "fr-unstranded"
    strandedness: str = ALIAS[alias_key]

    max_fraction: float = 0.0
    for key, value in fractions.items():
        if value > 0.7 and value > max_fraction:
            max_fraction = value
            alias_key = key
            strandedness = ALIAS[alias_key]

    return {"sequencing": sequencing, "strandedness": strandedness, "alias": alias_key}


if __name__ == "__main__":

    out: dict[str, str] = parse(filepath=sys.argv[1])

    row = ",".join(out.values())
    header = ",".join(out.keys())

    with open("infer.csv", "w") as fp:
        fp.write(f"{header}\n")
        fp.write(f"{row}\n")
