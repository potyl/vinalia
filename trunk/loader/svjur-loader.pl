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
my $tbl_attributes = {};
$tbl_attributes->{idx} = 0;

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
	$sql .= "VALUES (" . $wine->{wine_id} . ",$pid,$vid,$aid,$cid,'" . $wine->{year} . "');";

	$wine->{sql} = $sql; 

	$tbl_wines->{$wine->{wine_id}} = $wine;
}

print Dumper($tbl_wines);
print Dumper($tbl_attributes);


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

	my $attribute = shift @_;

	my %trans = (
		'HV' => 'hrozienkový výber',
		'BV' => 'bobuľový výber',
		'VzH' => 'výber z hrozna',
		'KAB' => 'kabinetné',
		'NZ' => 'neskorý zber',
		);		

	my $pattern = join "|", keys %trans;
	$pattern = qr/($pattern)/;

	$attribute =~ s/$pattern/$trans{$1}/gei;

	$attribute = 'akostné' unless ($attribute);

	unless ($tbl_attributes->{$attribute}) {
		
		$tbl_attributes->{$attribute}->{attribute_id} = ++$tbl_attributes->{idx};
		$tbl_attributes->{$attribute}->{name} = $attribute;

		my $sql = "INSERT INTO attributes (name,attribute_id) VALUES ('$attribute',";
		$sql .= $tbl_attributes->{$attribute}->{attribute_id} . ");";

		$tbl_attributes->{$attribute}->{sql} = $sql;
	}

	return $tbl_attributes->{$attribute}->{attribute_id};
		
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
