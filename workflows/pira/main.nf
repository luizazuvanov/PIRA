/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ID0 } from '../../subworkflows/local/ID0'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Default parameter input
params.str = "Hello world!"

// splitString process
process splitString {
    publishDir "results/lower"

    input:
    val x

    output:
    path 'chunk_*'

    script:
    """
    printf '${x}' | split -b 6 - chunk_
    """
}

// convertToUpper process
process convertToUpper {
    publishDir "results/upper"
    tag "$y"

    input:
    path y

    output:
    path 'upper_*'

    script:
    """
    cat $y | tr '[a-z]' '[A-Z]' > upper_${y}
    """
}

process convertToUpperPython {
    publishDir "results/upper_python"
    tag "$y"

    input:
    path y

    output:
    path 'upper_python_*'

    script:
    """
    python -c "import sys; print(sys.stdin.read().upper())" < $y > upper_python_${y}
    """
}

workflow PIRA {
    // ch_str = channel.of(params.str)     // Create a channel using parameter input
    // ch_chunks = splitString(ch_str)     // Split string into chunks and create a named channel
    // convertToUpper(ch_chunks.flatten()) // Convert lowercase letters to uppercase letters
    // convertToUpperPython(ch_chunks.flatten()) // Convert lowercase letters to uppercase letters in Python
    
    print "PIRA"
    ch_samplesheet = channel.fromPath(params.input)
    ch_samplesheet.view()
    
    ID0(ch_samplesheet)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
