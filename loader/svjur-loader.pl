#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Text::CSV::Simple;

# Read input data
my $wines;
if (my $inputfile = $ARGV[0] ) {

	$wines = parse_csv_wines($inputfile);
} else {	

	open ($inputfile, '<&STDIN') or die "Cannot duplicate STDIN\n";

	$wines = parse_csv_wines($inputfile);

	close($inputfile);
}
#print Dumper($wines);


my $tbl_wines = {};
my $tbl_varieties = {};
my $tbl_producers = {};
my $tbl_colors = {};
my $tbl_categories = {};

foreach my $wine ( @{$wines} ) {

	my $vid = get_variety_id($wine->{variety}, $wine->{category});
	my $pid = get_producer_id($wine->{producer});
	my $cid = get_category_id($wine->{category});
	my $aid = get_attribute_id($wine->{attribute});

	#$wine->{variety_id} = $vid;
	#$wine->{producer_id} = $pid;
	#$wine->{category_id} = $cid;
	#$wine->{attribute_id} = $aid;

	my $sql = "INSERT INTO wines (wine_id,producer_id,variety_id,attribute_id,category_id,year) ";
	$sql .= "VALUES (" . $wine->{wine_id} . ",$pid,$vid,$aid,$cid," . $wine->{year} . ");\n";

	$wine->{sql} = $sql; 

	$tbl_wines->{$wine->{wine_id}} = $wine;
}

print Dumper($tbl_wines);


## SUB ROUTINES ##

sub get_variety_id {
	
	return 1;
}

sub get_producer_id {
	
	return 1;
}

sub get_category_id {
	
	return 1;
}

sub get_attribute_id {
	
	return 1;
}

# 
# Parse CSV file
#
# Returns arrayref where each item is an hashref with column names as keys
#
sub parse_csv_wines {
	my $csvfile = shift @_;

	my $parser = Text::CSV::Simple->new({
	        sep_char => ",",
	        quote_char => '"',
	        escape_char => "\\",
	        binary => 1,
	});

	$parser->field_map(qw/wine_id variety year attribute producer category/);
	$parser->want_fields(0,1,2,3,4,5);

	my @data = $parser->read_file($csvfile);

	return \@data;
}
