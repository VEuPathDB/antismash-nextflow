#!/usr/bin/env nextflow

//---------------------------------------
// include the RNA seq workflow
//---------------------------------------

include { antismash } from  './modules/antismash.nf'

//======================================

  if(!params.fasta) {
    throw new Exception("Missing parameter params.inputDir")
  }
  if(!params.gff) {
    throw new Exception("Missing parameter params.inputCsv")
  }
  if(!params.organism) {
    throw new Exception("Missing parameter params.organism")
  }
  if(!params.resultDir) {
    throw new Exception("Missing parameter params.resultDir")
  }

inputFasta = Channel.fromPath(params.fasta, checkIfExists:true)
inputGff = Channel.fromPath(params.gff, checkIfExists:true)

workflow {
    antismash(inputFasta, inputGff)
}