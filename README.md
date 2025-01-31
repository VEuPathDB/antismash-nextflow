# antismash-nextflow
This workflow uses [antiSMASH](https://antismash.secondarymetabolites.org/#!/about) to identify and annoate secondary metabolites biosynthesis gene clusters from fungal genomes in the VEuPathDB database. More details on the antiSMASH can be found [here](https://academic.oup.com/nar/article/51/W1/W46/7151336?login=true)
It takes as input the oragnisms fasta files and GFF files specified in a csv file and the organism taxon. 

**<p align=left>Get Started</p>**
To run the workflow the following dependencies need to be installed

* Docker
> `https://docs.docker.com/engine/install/`
* Nextflow
> `curl https://get.nextflow.io | bash`

* The pull the git hub repo using the following command
> `git pull https://github.com/VEuPathDB/antismash-nextflow.git`

* Alternatively the workflow can be run directly using nextflow which pull down the repo. 
> `nextflow run VEuPathDB/antismash-nextflow -with-trace -c  <config_file> -r main`

<br />


**<p align=left>Input Data</p>**
Example of the input can be found in the `data` directoty. The following files are required to run the workflow.
* Fasta files of the organisms to be analyszd
* GFF files of the organisms to be analyzed (`See example in the data folder`)
* A CSV file with there columns in the format [SampleName,SampleName.gff,SampleName.fasta] (`See input.csv in the data directory`)
* The nextflow.config `see example in the parent directory`

**<p align=left>Ouput Results</p>**
Example of outputs can be found in the Results folder. For a sample (genome) analyzed the following files are generated.
* A sorted zipped GFF files of the containing annotation of where identified secondary metabolites mapped to the genomes `See example in Results directory under GFF`
* An index file of the sorted GFF file `See example in Results directory under GFF`


***<p align=center>Nextflow workflow diagram</p>*** 
```mermaid
flowchart TB
    subgraph " "
    v4["Fasta and GFF files"]
    v8["Oraganism taxon"]
    end
    subgraph " "
    
    v12[" "]
    end
    subgraph antismash
    v7([repairGff])
    v9([antiSmash])
    v10([makeGff])
    v11([sortAndIndexGff])
    v5(( ))
    end
    v4 --> v5
    v5 --> v7
    v7 --> v9
    v8 --> v9
    v9 --> v10
    v10 --> v11
    v11 --> v12
```