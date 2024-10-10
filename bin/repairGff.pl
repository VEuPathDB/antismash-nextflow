#!/usr/bin/perl

use strict;

use Bio::Tools::GFF;

my $gffFile = $ARGV[0];
my $outputFile = $ARGV[1];


# First pass through the file, find the longest transcript for each coding gene

my %geneToLongestTranscript;
my %geneToLongestTranscriptLength;

my $gffio = Bio::Tools::GFF->new(-file => $gffFile, -gff_version => 3);

while(my $feature = $gffio->next_feature()) {
    next unless($feature->primary_tag() eq 'mRNA' or $feature->primary_tag() eq 'transcript');

    my $transcriptLength = $feature->end - $feature->start + 1;
    my ($gene) = $feature->get_tag_values("Parent");
    my ($transcriptId) = $feature->get_tag_values("ID");
    if($transcriptLength > $geneToLongestTranscriptLength{$gene}) {
        $geneToLongestTranscriptLength{$gene} = $transcriptLength;
        $geneToLongestTranscript{$gene} =  $transcriptId
    }
}
$gffio->close();



# Second Pass
# remove Name tag
# keep only protein coding genes
# keep only the longest transcript
my $gffio2 = Bio::Tools::GFF->new(-file => $gffFile, -gff_version => 3);

while(my $feature = $gffio2->next_feature()) {
    my ($id) = $feature->get_tag_values("ID");

    if($feature->has_tag("Name")) {
        $feature->remove_tag("Name");
    }

    my $parent;
    if($feature->has_tag("Parent")) {
        ($parent) = $feature->get_tag_values("Parent");
    }
    my $geneId;
    if($feature->has_tag("gene_id")) {
        ($geneId) = $feature->get_tag_values("gene_id");
    }


    # if this is the gene row OR this row's parent is the longest transcript for this gene
    if($geneToLongestTranscript{$id} ||
        (defined $parent && $id eq $geneToLongestTranscript{$parent}) ||
        (defined $geneId && defined $parent && $parent eq $geneToLongestTranscript{$geneId})) {

        $feature->gff_format(Bio::Tools::GFF->new(-gff_version => 3));
        print $feature->gff_string . "\n";
    }
}
