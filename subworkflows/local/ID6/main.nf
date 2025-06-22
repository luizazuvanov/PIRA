include { STRINGTIE_STRINGTIE } from '../../../modules/nf-core/stringtie/stringtie/main'
include { STRINGTIE_MERGE     } from '../../../modules/nf-core/stringtie/merge/main'

workflow ID6_STRINGTIE {

    take:
    ch_input

    main:

    STRANDEDNESS(
        ch_input.map { it -> tuple([id: it.experiment], it.infer) }
    )

    STRINGTIE_STRINGTIE(
        ch_input.map { it -> tuple(
            [id: it.experiment, alignment: it.alignment, strandedness: STRANDEDNESS.out.strandedness], 
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

process STRANDEDNESS {
  tag "$meta.id"
  label 'process_single'

  input:
  tuple val(meta), path(infer)

  output:
  val(strandedness), emit: strandedness

  script:
  strandedness = ''
  """
  echo ${strandedness}
  """
}
