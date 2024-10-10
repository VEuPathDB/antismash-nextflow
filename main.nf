#!/usr/bin/env nextflow

//---------------------------------------
// include the RNA seq workflow
//---------------------------------------

include { antismash } from  './modules/antismash.nf'

//======================================

  if(!params.inputDir) {
    throw new Exception("Missing parameter params.inputDir")
  }
  if(!params.inputCsv) {
    throw new Exception("Missing parameter params.inputCsv")
  }
  
  if(!params.organism) {
    throw new Exception("Missing parameter params.organism")
  }
  if(!params.results) {
    throw new Exception("Missing parameter params.results")
  }

inputCsv = Channel.fromPath(params.inputCsv, checkIfExists:true)
inputDir = Channel.fromPath(params.inputDir, checkIfExists:true)


workflow {
    antismash(inputCsv, inputDir)
}