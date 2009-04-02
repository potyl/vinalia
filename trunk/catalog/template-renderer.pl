#!/usr/bin/perl

use strict;
use warnings;

use Template;
use DBI;
use Encode;
use FindBin;

use Data::Dumper;


# Start the main function
exit main();


sub main {
	
	die "Usage: template\n" unless @ARGV;
	my ($file) = @ARGV;

	# Create a database connection
	my $dbi = DBI->connect(
		"dbi:Pg:dbname=vinalia;host=localhost", 
		"vinalia", 
		"vino", 
		{
			AutoCommit => 0,
			RaiseError => 1,
		}
	);
	
	my $template = get_tt_instance($dbi);
	
	my $success;
	eval {
		$success = $template->process($file);
	};
	if (my $error = $@) {
		die "Failed to apply template because: $error";
	}
	if (! $success) {
		die "Template failed to process $file because: " . $template->error;
	}
	
	$dbi->disconnect();
	
	return 0;
}


#
# Creates a new instance of the template engine
#
sub get_tt_instance {
	my ($dbi) = @_;

	# Create a reference to the template engine
	my $template = Template->new(
		{
			EVAL_PERL    => 1,
			INTERPOLATE  => 1, 
			
			ABSOLUTE     => 1,
			CACHE_SIZE   => 0,
			
			VARIABLES => {
				SQL => sub { do_select($dbi, @_) },
			},
		}
	);
	

	return $template;
}




#
# Returns all the data provided by the given SQL query.
# All data will be marked as UTF-8
#
sub do_select {
	
	# Arguments
	my $self = shift;
	my ($query) = @_;
	
	my @data = ();
	
	my $statement = $self->dbi->prepare($query);
	$statement->execute();
	while (my $row = $statement->fetchrow_hashref) {
		# Needed because Postgres return always the same reference to $row
		my $copy = {};
		while (my ($key, $value) = each %{ $row }) {
			Encode::_utf8_on($value);
			$copy->{$key} = $value;
		}
		push @data, $copy;
	}
	$statement->finish;

	return \@data;	
}



