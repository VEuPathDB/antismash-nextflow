#!/usr/bin/perl

use strict;

use Bio::SeqIO;
use Bio::Tools::GFF;

use File::Basename;

use Data::Dumper;


#NOTE:  usage:  perl parseAntismash.pl Results/FungiDB-68_AfumigatusAf293/FungiDB-68_AfumigatusAf293.gbk FungiDB-68_AfumigatusAf293.gff
my $gbfile = $ARGV[0];
my $gffFile = $ARGV[1]; # the GFF file here is the ORIGINAL GFF

my $io = Bio::SeqIO->new(-file => $gbfile, -format => "genbank" );

my %keepers = ("CDS" => 1,
                "exon" => 1,
                #"five_prime_UTR" => 1,
                #"mRNA" => 1,
                "protocluster" => 1,
                "proto_core" => 1,
                "region" => 1,
                #"three_prime_UTR" => 1,
                "cand_cluster" => 1
);

my %geneInfo;
my %transcriptsToGene;

my %cdsExcludes = ("ID" => 1,
                "gene" => 1,
                "phase" => 1,
                "protein_source_id" => 1,
                "source" => 1,
                "transl_table" => 1,
                "translation" => 1,
                "Parent" => 1,
    );


while (my $seq = $io->next_seq()){
    my $sequenceSourceId = $seq->display_id();

    my $currentRegion = undef;

    foreach my $feature ($seq->get_SeqFeatures()) {
        my $primaryTag = $feature->primary_tag();

        next unless($keepers{$primaryTag});

        if($primaryTag eq 'protocluster' || $primaryTag eq 'proto_core') {
            &updateProtoClusterAndCore($primaryTag, $feature, $sequenceSourceId);
        }

        if($primaryTag eq 'cand_cluster') {
            &updateCandCluster($primaryTag, $feature, $sequenceSourceId);
        }

        if ($primaryTag eq 'region'){
            &updateRegion($primaryTag, $feature, $sequenceSourceId);

            # Update the current region to this feature
            $currentRegion = $feature;
        }

        if ($primaryTag eq 'CDS' || $primaryTag eq 'exon'){
            # if we are within a region, get the cds tags of interest
            if($currentRegion) {
                if($feature->overlaps($currentRegion)){
                    my ($geneId) = $feature->get_tag_values("gene_id");

                    foreach my $tag ($feature->get_all_tags()) {
                        unless($cdsExcludes{$tag}) {
                            my @values = $feature->get_tag_values($tag);
                            $geneInfo{$geneId}->{$tag} = \@values;
                        }
                    }
                    # parent here will be for exon and will be the transcript
                    if($feature->has_tag("Parent")) {
                        my ($parent) = $feature->get_tag_values("Parent");
                        $transcriptsToGene{$parent} = $geneId;
                    }
                }
            }
            next; #don't print the CDS or exon row to gff here
        }

        $feature->gff_format(Bio::Tools::GFF->new(-gff_version => 3));
        print $feature->gff_string . "\n";
    }
}

my $gffio = Bio::Tools::GFF->new(-file => $gffFile, -gff_version => 3);

while(my $feature = $gffio->next_feature()) {
    my ($id) = $feature->get_tag_values("ID");

    my $parent;
    if($feature->has_tag("Parent")) {
        ($parent) = $feature->get_tag_values("Parent");
    }

    # Only keep rows for genes within the regions (coding or non coding)
    next unless($geneInfo{$id} || (defined $parent && ($geneInfo{$parent} || $transcriptsToGene{$parent})));

    # add the antismash tags for the coding genes
    if($geneInfo{$id}) {
        my $hash = $geneInfo{$id};
        foreach my $key (keys %$hash) {
            foreach my $value (@{$hash->{$key}}) {
                $feature->add_tag_value($key, $value);
            }
        }

        $feature->primary_tag("gene");
    }

    $feature->gff_format(Bio::Tools::GFF->new(-gff_version => 3));
    print $feature->gff_string . "\n";
}
$gffio->close();


sub updateProtoClusterAndCore {
    my ($primaryTag, $feature, $sequenceSourceId) = @_;

    my ($protoClusterNumber) = $feature->get_tag_values("protocluster_number");

    my $featureFullName = $sequenceSourceId . "_${primaryTag}_" . $protoClusterNumber;

    # first check that we don't already have an ID or Parent
    if($feature->has_tag("ID") || $feature->has_tag("Parent")) {
        die "protocluster and proto_core should not alreaday have ID or Parent set";
    }

    $feature->add_tag_value('ID', $featureFullName);
    if($primaryTag eq 'proto_core') {
        my $protoclusterFullName = $sequenceSourceId . "_protocluster_" . $protoClusterNumber;
        $feature->add_tag_value('Parent', $protoclusterFullName);
    }

}

sub updateCandCluster {
    my ($primaryTag, $feature, $sequenceSourceId) = @_;



    my @protoclusters = $feature->get_tag_values("protoclusters");
    $feature->remove_tag("protoclusters");
    foreach(@protoclusters) {
        my $protoclusterFullName = $sequenceSourceId . "_protocluster_" . $_;
        $feature->add_tag_value('protocolusters', $protoclusterFullName);
    }

    my ($candidateClusterNumber) = $feature->get_tag_values("candidate_cluster_number");
    my $candidateClusterFullName = $sequenceSourceId . "_${primaryTag}_" . $candidateClusterNumber;
    $feature->add_tag_value('ID', $candidateClusterFullName);
}

sub updateRegion {
    my ($primaryTag, $feature, $sequenceSourceId) = @_;

    my ($regionNumber) = $feature->get_tag_values("region_number");
    my @candidateClusterNumbers = $feature->get_tag_values("candidate_cluster_numbers");
    $feature->remove_tag("candidate_cluster_numbers");
    foreach(@candidateClusterNumbers) {
        my $candidateClusterFullName = $sequenceSourceId . "_cand_cluster_" . $_;
        $feature->add_tag_value('candidate_cluster_numbers', $candidateClusterFullName);
    }
    my $regionId = $sequenceSourceId . "_${primaryTag}_" . $regionNumber;
    $feature->add_tag_value('ID', $regionId);
}


1;
