#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process repairGff {
  container = "bioperl/bioperl:stable"

  input:
    path(gff)

  output:
    tuple path(gff), path("repaired.gff")

  script:    
    """
    repairGff.pl $gff > repaired.gff
    """
}

process antiSmash {
  container 'antismash/standalone:8.0.4'

  input:
    path(fasta)
    val(organism)
    tuple path(gff), path(repairedGff)

  output:
    tuple path("results/output.gbk"), path(gff)

  script:
    """
    antismash ${fasta} --taxon ${organism} --genefinding-gff3 ${repairedGff} --output-dir ./results --output-basename output -c 1
    """
}

process makeGff {
  container = "bioperl/bioperl:stable"
  
  input:
    tuple path(gbk), path(gff)

  output:
    path("corrected.gff")

  script:
    """
    processGffv1.pl ${gbk} ${gff} > corrected.gff
    """
}

process sortAndIndexGff {
  container 'staphb/htslib'
  
  publishDir "${params.resultDir}", mode: 'copy'

  input:
    path(correctedGff)

  output:
    path('antismash.gff*')

  script:
    """
    sort -k1,1 -k4,4n ${correctedGff} > antismash.gff
    cp antismash.gff antismash.gff.bkup
    bgzip antismash.gff
    mv antismash.gff.bkup antismash.gff
    tabix -p gff antismash.gff.gz
    """
}

workflow antismash {

  take:
    inputFasta
    inputGff
    
  main:
    repairedGff = repairGff(inputGff)
    smash = antiSmash(inputFasta, params.organism, repairedGff)
    processGff = makeGff(smash)
    indexGff = sortAndIndexGff(processGff)
    
}