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