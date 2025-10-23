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
  container = 'antismash/standalone-lite:7.1.0'

  input:
    path(fasta)
    val(organism)
    tuple path(gff), path(repairedGff)

  output:
    tuple path("*.gbk"), path(gff)

  script:
    """
    antismash ${fasta} --taxon ${organism} --genefinding-gff3 ${repairedGff} --output-dir . --output-basename output -c 1
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
  container = "bioperl/bioperl:stable"
  
  publishDir "${params.resultDir}/Gff", mode: 'copy'

  input:
    path(correctedGff)

  output:
    path('sorted.gff*')

  script:
    """
    sort -k1,1 -k4,4n ${correctedGff} > sorted.gff
    cp sorted.gff sorted.gff.bkup
    bgzip sorted.gff
    mv sorted.gff.bkup sorted.gff
    tabix -p gff sorted.gff.gz
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