#!/usr/bin/perl

=head1 NAME

load-wine-cli.pl - Loads the wine list throgh a command line interface

=head2 DESCRIPTION

This program provides an interactive prompt used to load the wines.

=cut

# Pragmas
use strict;
use warnings;

# Used modules from CPAN
use DBI;
use Term::ReadLine;


# Debug
use Data::Dumper;

exit main();

sub main {
	
	# Connect to the database
	my $dbi = DBI->connect(
		"dbi:Pg:dbname=vinalia;host=127.0.0.1", 
		"vinalia", 
		"vino", 
		{
			AutoCommit => 1,
			RaiseError => 1,
		}
	);
	
	my $select_score = $dbi->prepare("SELECT * FROM scores WHERE wine_id = ? AND judge_id = ?");
	my $update_score = $dbi->prepare("UPDATE scores SET score = ? WHERE score_id = ?");
	my $insert_score = $dbi->prepare("INSERT INTO scores (judge_id, wine_id, score) VALUES (?, ?, ?)");
	
	my %judges = load_object($dbi, judges => 'judge_id');
	my %wines = load_object($dbi, wines => 'wine_id');
	
	# Group the judges by group!
	my %groups = ();
	foreach my $judge (values %judges) {
		my $group_id = $judge->{group_id};
		my ($groups) = ($groups{$group_id} ||= []);
		push @{ $groups }, $judge;
	}
	# Sort the groups
	while (my ($id, $groups) = each %groups) {
		my @groups = @{ $groups };
		@groups = sort { $a->{judge_id} <=> $b->{judge_id} } @groups;
		$groups{$id} = \@groups;
	}
	
	my $term = Term::ReadLine->new("Vinalia");
	$term->ornaments(0);
	my $OUT = $term->OUT() || *STDOUT;
	
	my $wine_id;
	WINE:
	while (defined ($wine_id = ask_number($term, "Wine"))) {
		
		# Find the wine
		my $wine = $wines{$wine_id};
		if (! $wine) {
			print $OUT "No such wine\n";
			next;
		}
		
		# Find the judges
		my $judges = $groups{$wine->{group_id}};
		if (!$judges) {
			print $OUT "Can't find the judges!\n";
			next;
		}
		
		# Ask the scores of each judge
		JUDGE:
		foreach my $judge (@{ $judges }) {
			
			my $name = "$judge->{judge_id}) $judge->{name} $judge->{family_name}";
			
			# Find the score of the judge
			my $score = get_object($dbi, $select_score, $wine_id, $judge->{judge_id});
			if ($score) {
				# Display the old value, allow the user to change it
				my $value = ask_number($term, "$name [$score->{score}]", 1);
				last WINE unless defined $value;
				next JUDGE if $value eq "";
				$update_score->execute($value, $score->{score_id});
			}
			else {
				# Ask for a new value
				my $value = ask_number($term, "$name");
				last WINE unless defined $value;

				$insert_score->execute($judge->{judge_id}, $wine_id, $value);
			}
		}
	}
	
	
	$dbi->disconnect();
	print "\n";

	return 0;
}


#
# Ask the user for a number. This function will return undef if there's no more
# input. If empty numbers are allowed and no number is given then "" will be
# returned otherwise the given number will be returned.
#
sub ask_number {
	my ($term, $prompt, $allow_empty) = @_;
	
	# Get the user's value
	while (1) {
		my $input = $term->readline("$prompt: ");
		return undef unless defined $input;
		
		if (my ($number) = ($input =~ /^\s*(\d+)\s*$/)) {
			return $number;
		}
		elsif ($allow_empty && $input =~ /^\s*$/) {
			return "";
		}
	}
}


#
# Assumes that the query will return a single row
#
sub get_object {

	my ($dbi, $select, @args) = @_;
	
	# Find the objects
	$select->execute(@args);
	my $row = $select->fetchrow_hashref('NAME_lc');
	return undef unless $row;
	
	my $other = $select->fetchrow_hashref('NAME_lc');
	die "Expected only one row and got two ", Dumper($other) if defined $other;

	return $row;
}


#
# Loads the given objects
#
sub load_object {

	my ($dbi, $table, $key) = @_;
	
	# Find the objects
	my $select = $dbi->prepare("SELECT * FROM $table");
	$select->execute();
	my %objects = ();
	while (my $row = $select->fetchrow_hashref('NAME_lc')) {
		my $id = $row->{$key};
		$objects{$id} = $row;
	}

	return %objects;
}
