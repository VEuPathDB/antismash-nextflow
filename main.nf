#!/usr/bin/env nextflow

//---------------------------------------
// include the RNA seq workflow
//---------------------------------------

include { antismash } from  './modules/antismash.nf'

//======================================

workflow {
  if(!params.fasta) {
    error "Missing parameter params.inputDir"
  }
  if(!params.gff) {
    error "Missing parameter params.inputCsv"
  }
  if(!params.organism) {
    error "Missing parameter params.organism"
  }
  if(!params.resultDir) {
    error "Missing parameter params.resultDir"
  }

  inputFasta = channel.fromPath(params.fasta, checkIfExists:true)
  inputGff = channel.fromPath(params.gff, checkIfExists:true)

    antismash(inputFasta, inputGff)
}