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
$tbl_varieties->{idx} = 1;

my $tbl_producers = {};
$tbl_producers->{idx} = 1;

my $tbl_colors = {};
$tbl_colors->{idx} = 1;

my $tbl_categories = {};
$tbl_categories->{idx} = 1;

my $tbl_attributes = {};
$tbl_attributes->{idx} = 1;

foreach my $wine ( @{$wines} ) {

	my $pid = get_producer_id($wine->{producer});
	my $cid = get_category_id($wine->{category});
	my $aid = get_attribute_id($wine->{attribute});
	my $vid = get_variety_id($wine->{variety}, $wine->{category});

	#$wine->{variety_id} = $vid;
	#$wine->{producer_id} = $pid;
	#$wine->{category_id} = $cid;
	#$wine->{attribute_id} = $aid;

	my $sql = "INSERT INTO wines (wine_id,producer_id,variety_id,attribute_id,category_id,year) ";
	$sql .= "VALUES (" . $wine->{wine_id} . ",$pid,$vid,$aid,$cid,'" . $wine->{year} . "');";

	$wine->{sql} = $sql; 

	$tbl_wines->{$wine->{wine_id}} = $wine;
	$tbl_wines->{idx} = $wine + 1;
}

#print Dumper($tbl_wines);
#print Dumper($tbl_attributes);
#print Dumper($tbl_producers);
#print Dumper($tbl_categories);
#print Dumper($tbl_colors);
#print Dumper($tbl_varieties);

foreach my $row ( keys %{$tbl_colors} ) {

	next if ($row eq 'idx');
	print $tbl_colors->{$row}->{sql}, "\n";
}
print "SELECT setval('colors_color_id_seq'," . $tbl_colors->{idx} . ");\n\n";

foreach my $row ( keys %{$tbl_categories} ) {

	next if ($row eq 'idx');
	print $tbl_categories->{$row}->{sql}, "\n";
}
print "SELECT setval('categories_category_id_seq'," . $tbl_categories->{idx} . ");\n\n";

foreach my $row ( keys %{$tbl_attributes} ) {

	next if ($row eq 'idx');
	print $tbl_attributes->{$row}->{sql}, "\n";
}
print "SELECT setval('attributes_attribute_id_seq'," . $tbl_attributes->{idx} . ");\n\n";

foreach my $row ( keys %{$tbl_varieties} ) {

	next if ($row eq 'idx');
	print $tbl_varieties->{$row}->{sql}, "\n";
}
print "SELECT setval('varieties_variety_id_seq'," . $tbl_varieties->{idx} . ");\n\n";

foreach my $row ( keys %{$tbl_producers} ) {

	next if ($row eq 'idx');
	print $tbl_producers->{$row}->{sql}, "\n";
}
print "SELECT setval('producers_producer_id_seq'," . $tbl_producers->{idx} . ");\n\n";

foreach my $row ( keys %{$tbl_wines} ) {

	next if ($row eq 'idx');
	print $tbl_wines->{$row}->{sql}, "\n";
}
#print "SELECT setval('wines_wine_id_seq'," . $tbl_wines->{idx} . ");\n";


## SUB ROUTINES ##

sub get_variety_id {
	
	my $variety = shift @_;
	my $category = shift @_;

	die "NO VARIETY!\n" unless ($variety);

	unless ($tbl_varieties->{$variety}) {
		
		$tbl_varieties->{$variety}->{variety_id} = $tbl_varieties->{idx}++;
		$tbl_varieties->{$variety}->{name} = $variety;

		my $color_id = get_color_id($category);

		my $sql = "INSERT INTO varieties (name,variety_id,color_id) VALUES ('$variety',";
		$sql .= $tbl_varieties->{$variety}->{variety_id} . ",$color_id);";

		$tbl_varieties->{$variety}->{sql} = $sql;
	}

	return $tbl_varieties->{$variety}->{variety_id};
}

sub get_color_id {
	
	my $catnumber = shift @_;
	my $color;

	if ($catnumber) {
	
		if ($catnumber =~ m/^\s*4\s*$/) {
			$color = 'červené';
		} elsif ($catnumber =~ m/^\s*3\s*$/) {
			$color = 'ružové';
		} elsif ($catnumber =~ m/^\s*(1|2)\s*$/) {
			$color = 'biele';
		} else {
			die "UNKNOWN COLOR\n";
		}
	} else {
		$color = 'unknown';
	}

	unless ($tbl_colors->{$color}) {
		
		$tbl_colors->{$color}->{color_id} = $tbl_colors->{idx}++;
		$tbl_colors->{$color}->{name} = $color;

		my $sql = "INSERT INTO colors (name,color_id) VALUES ('$color',";
		$sql .= $tbl_colors->{$color}->{color_id} . ");";

		$tbl_colors->{$color}->{sql} = $sql;
	}

	return $tbl_colors->{$color}->{color_id};
}

sub get_producer_id {
	
	my $producer = shift @_;

	die "NO PRODUCER!\n" unless ($producer);

	unless ($tbl_producers->{$producer}) {
		
		$tbl_producers->{$producer}->{producer_id} = $tbl_producers->{idx}++;
		$tbl_producers->{$producer}->{name} = $producer;

		my $sql = "INSERT INTO producers (family_name,address,producer_id) VALUES ('$producer','',";
		$sql .= $tbl_producers->{$producer}->{producer_id} . ");";

		$tbl_producers->{$producer}->{sql} = $sql;
	}

	return $tbl_producers->{$producer}->{producer_id};
	
}

sub get_category_id {
	
	my $catnumber = shift @_;

	my $category = 'unknown';
	if ($catnumber =~ m/^\s*1\s*$/) {
		$category = 'suché';
	} elsif ($catnumber =~ m/^\s*(2|3|4)\s*$/) {
		$category = 'ostatné';
	}

	unless ($tbl_categories->{$category}) {
		
		$tbl_categories->{$category}->{category_id} = $tbl_categories->{idx}++;
		$tbl_categories->{$category}->{name} = $category;

		my $sql = "INSERT INTO categories (name,category_id) VALUES ('$category',";
		$sql .= $tbl_categories->{$category}->{category_id} . ");";

		$tbl_categories->{$category}->{sql} = $sql;
	}

	return $tbl_categories->{$category}->{category_id};
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
		
		$tbl_attributes->{$attribute}->{attribute_id} = $tbl_attributes->{idx}++;
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
