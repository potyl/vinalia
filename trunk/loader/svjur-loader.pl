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

print Dumper($wines);

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
