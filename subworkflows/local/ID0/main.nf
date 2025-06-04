process step {
    publishDir "results/step"

    input:
    path data_path

    output:
    path 'step_output.txt'

    script:
    """
    echo "Processing data from: ${data_path}" > step_output.txt
    cat ${data_path} >> step_output.txt
    """
}

workflow ID0 {

    take:
    ch_file

    main:
    
    print "ID0"
    ch_file.view()

    step(ch_file)
}