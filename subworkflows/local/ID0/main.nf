process step {

    input:
    path data_path

    output:
    path 'data.csv'

    script:
    """
    # Clean Experiment (column 2) and Condition (column 3)
    awk -F ',' 'NR == 1 {print; next} {
        gsub(/[^a-zA-Z0-9]/, "", \$2); 
        gsub(/[^a-zA-Z0-9]/, "", \$3); 
        print
    }' OFS=',' "$data_path" > "data.csv"
    """
}

workflow ID0 {

    take:
    ch_file

    main:
    step(ch_file)

    emit:
    step.out
}