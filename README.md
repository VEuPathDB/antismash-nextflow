# antismash-nextflow

Nextflow pipeline that runs [antiSMASH](https://antismash.secondarymetabolites.org/#!/about) to identify and annotate secondary metabolite biosynthesis gene clusters in fungal genomes.

## Overview

Secondary metabolite gene clusters (e.g. polyketide synthases, non-ribosomal peptide synthetases) are important functional annotations for fungal genomes in VEuPathDB (FungiDB). This pipeline runs antiSMASH against a genome's assembly and existing gene models, repairs and reconciles the antiSMASH output against the original GFF, and produces a sorted, indexed GFF3 of predicted secondary metabolite clusters that is loaded into the VEuPathDB genome browser and annotation pipeline.

## Requirements

- [Nextflow](https://www.nextflow.io/)
- [Singularity](https://sylabs.io/singularity/) — `nextflow.config` enables Singularity (`singularity { enabled = true }`) and binds a local antiSMASH database directory (`/project/eupathdblab/software_databases/antismash-8.0.4`) into the container; the pipeline is configured by default to run on an LSF cluster (`process.executor = 'lsf'`)

## Usage

```
nextflow run VEuPathDB/antismash-nextflow -r main \
  --fasta /path/to/genome.fasta \
  --gff /path/to/genome.gff \
  --organism fungi \
  --resultDir /path/to/results \
  -resume -C my.config
```

The pipeline has a single, unnamed entry point (`workflow { ... }` in `main.nf`), so no `-entry` flag is needed.

Steps performed:
1. `repairGff` — runs `repairGff.pl` to identify the longest transcript per gene and repair the input GFF3 so antiSMASH's gene-finding step can consume it.
2. `antiSmash` — runs `antismash` against the genome FASTA, using the repaired GFF3 for gene-finding and `params.organism` to select the antiSMASH taxon model (e.g. `fungi`).
3. `makeGff` — runs `processGffv1.pl` to parse the antiSMASH GenBank output (`output.gbk`) and translate the identified clusters, CDS, and regions back into GFF3 coordinates against the original gene models.
4. `sortAndIndexGff` — sorts the resulting GFF3, compresses it with `bgzip`, and indexes it with `tabix`, publishing `antismash.gff.gz` (and its `.tbi` index) to `params.resultDir`.

## Key Parameters

| Parameter | Description | Default |
|---|---|---|
| `params.fasta` | Path to the genome assembly FASTA | `data/input.fasta` |
| `params.gff` | Path to the genome's GFF3 gene models | `data/input.gff` |
| `params.organism` | antiSMASH taxon model to use (e.g. `fungi`) | `fungi` |
| `params.resultDir` | Directory the final indexed GFF is published to | `results` |

## Output

A sorted, bgzip-compressed GFF3 file, `antismash.gff.gz`, plus its `tabix` index (`antismash.gff.gz.tbi`), published to `params.resultDir`. The GFF3 annotates predicted secondary metabolite biosynthesis gene clusters (protoclusters, candidate clusters, and their CDS/region features) mapped onto the genome's original coordinate system.
