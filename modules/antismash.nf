#!/usr/bin/env nextflow
nextflow.enable.dsl=2 

process repairGff {
    input:
    tuple val(uniqueId), path(gff), path(fasta)

    output:
     tuple val(uniqueId), path(gff), path(fasta)
     path("repaired.gff")

    script:
    
    """
    repairGff.pl $gff >repaired.gff
    """

  }


process antiSmash {
   errorStrategy 'ignore'   
   maxForks = 10   

   input:
   tuple val(uniqueId), path(gff), path(fasta)
   path(repairedGff)
   val(taxon)


   output:
   path("${uniqueId}/${uniqueId}.gbk"), emit: gbk
   tuple val(uniqueId), path(gff), path(fasta), emit: orig

    script:

   """
   singularity exec docker://antismash/standalone antismash ${fasta} --taxon ${taxon} --genefinding-gff3 ${repairedGff}  --output-dir ${uniqueId}  --output-basename ${uniqueId}

   """


  }


process makeGff {

   input:
   path(gbk)
   tuple val(uniqueId), path(gff), path(fasta)


   output:
    path("${uniqueId}.corrected.gff"), emit: gff
    val(uniqueId), emit: uniqueId

   """
   processGffv1.pl ${gbk} ${gff} > ${uniqueId}.corrected.gff
   """
  }


process sortAndIndexGff {
   
   publishDir "${params.results}/Gff", pattern: '*gff*', mode: 'copy'


   input:
    path(gff)
    val(uniqueId)

   output:
    path('*gff*')

   script:
    template 'sortAndIndexGff.bash'


 }

/**
* return a tuple of 2 files. one gff and one fasta
*/
def csvToTupleChannel(csv, inputDir) {
    return Channel.fromPath(csv)
        .splitCsv(header:false)
        .map { row-> tuple(row[0], file(inputDir + "/" + row[1]), file(inputDir + "/" + row[2])) };
}


workflow antismash {

  take:
    inputCsv
    inputDir
  main:
    gffAndFasta = csvToTupleChannel(params.inputCsv, params.inputDir)
    repairedGff = repairGff(gffAndFasta)

    smash = antiSmash(repairedGff, params.organism)

    processGff = makeGff(smash)

    indexGff = sortAndIndexGff(processGff)

}