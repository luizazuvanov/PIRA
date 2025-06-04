process step {

    input:
    val download_line

    script:
    """
    echo "Processing download line: $download_line"
    """
}

workflow ID1 {

    take:
    ch_download_line

    main:
    step(ch_download_line)
}