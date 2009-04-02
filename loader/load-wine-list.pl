#!/usr/bin/perl

=head1 NAME

load-wine-list.pl - Loads the wine list

=head2 DESCRIPTION

This program loads the wine list into the C<vinalia> database.
The wine list is imported from a CVS file where the separator 
is a C<tab>. The columns are expected to be:

=over

=item Wine ID 

=item Producer name (Optional)

=item Producer family name 

=item Producer address 

=item Wine variety 

=item Wine attribute 

=item Wine category 

=item Wine year 

=item Wine note

=back

This program will try to resuse all existing data, thus it 
could be use for incremental uploads of wine lists.


B<NOTE:> This program assumes that the database is accessed 
exclusively by this program during it's execution.

=cut

# Pragmas
use strict;
use warnings;

# Used modules from CPAN
use DBI;
use Lingua::EN::Inflect qw (PL);
use Log::Log4perl qw(:easy);
use FindBin;

# Debug
use Data::Dumper;



main();

sub main {
	
	##
	# Recieve all the arguments
	my $file = shift @ARGV or die "Usage: file";


	# Initalize the loggin mechanism
	Log::Log4perl->init_once("$FindBin::Bin/logger.conf");
	
	INFO("Program Started");
	
	# Extract the contents of the file
	my @columns = qw(wine_id name family_name address variety attribute category year note);
	my @contents = load_csv_file($file, @columns);
	
	# Connect to the database
	my $dbi = DBI->connect(
		"dbi:Pg:dbname=vinalia;host=127.0.0.1", 
		"vinalia", 
		"vino", 
		{
			AutoCommit => 0,
			RaiseError => 1,
		}
	);
	
	# Create the statements
	my $statements = {
		
		wine => {
			select => $dbi->prepare("SELECT * FROM wines WHERE wine_id = ?"),
			insert => $dbi->prepare("INSERT INTO wines (wine_id, producer_id, variety_id, attribute_id, category_id, year, note) VALUES (?, ?, ?, ?, ?, ?, ?)"),
		},
		
		producer => {
			select => $dbi->prepare("SELECT * FROM producers WHERE LOWER(family_name) = LOWER(?)"),
			insert => $dbi->prepare("INSERT INTO producers (producer_id, family_name, name, address) VALUES (NEXTVAL('producers_producer_id_seq'), ?, ?, ?)"),
		},
		
		create_generic_statements($dbi, qw(color variety attribute category)),
	};

	
	# Insert the data
	my $row = 0;
	CONTENT:
	foreach my $content (@contents) {
		
		# Count the rows
		++$row;
		
		# Skip if id is not a number
		if ($content->{wine_id} !~ /^\d+$/) {
			WARN("Row $row is skipped because id is not a number ($content->{wine_id})");
			next CONTENT;
		}
		
		if (! defined $content->{family_name} or $content->{family_name} =~ /^\s*$/) {
			WARN("Row $row seems empty, there is no family name, skipping");
			next CONTENT;
		}
		
		INFO("Row $row wine $content->{wine_id}: $content->{variety} from $content->{name} ($content->{year})");
		
		# Get the producer id
		my @references = ();
		push @references, add_object($dbi, $statements, 'producer', @$content{qw(family_name name address)});

		# Get the generic fields (variety/attribute/category) id
		foreach my $field (qw(variety attribute category)) {
			push @references, add_object($dbi, $statements, $field, $content->{$field});
		}
		
		# Finally add the wine
		add_object(
			$dbi, 
			$statements, 
			'wine', 
			($content->{wine_id}, @references, $content->{year}, $content->{note}),
		);
	}
	
	# Commit the transactions and disconnect
	INFO("Commit the transactions");
	$dbi->commit;
	$dbi->disconnect;
	
	INFO("Program Ended");
}

#
# Loads the contents of the CVS file
#
sub load_csv_file {
	
	my ($file, @columns) = @_;
	
	
	my @records = ();
		
	# Load the contents of the excel file
	open my $handle, $file or die "Can't read file $file";
	
	while (my $line = <$handle>) {
		
		# Get the column's data
		chomp $line;
		my @content = split /\t/, $line;
		
		# Clean the data 
		foreach my $content (@content) {
			# Trim white spaces
			$content =~ s/^\s+//;
			$content =~ s/\s+$//;
		}
		
		# Construct a record
		my $record = {};
		@$record{@columns} = @content;
		
		# Keep the record
		push @records, $record;
	}
	close $handle;
	
	
	return @records;
}


#
#Creates the generic statements.
#
sub create_generic_statements {
	
	my ($dbi, @fields) = @_;
	
	my %statements = ();
	
	# Add the generic tables
	foreach my $field (@fields) {
		my $table = PL($field);
		
		my $insert = "INSERT INTO $table (${field}_id, name) VALUES (NEXTVAL('${table}_${field}_id_seq'), ?)";
		my $select = "SELECT * FROM $table WHERE LOWER(name) = LOWER(?)";
		
		DEBUG("Creating INSERT statement for table $table: $insert");
		DEBUG("Creating SELECT statement for table $table: $select");
		
		$statements{$field} = {
			insert => $dbi->prepare($insert),
			select => $dbi->prepare($select),
		};
	};

	return %statements;
}


#
#This method adds a new object into the database if the object doesn't exist.
#The return value is the id corresponding to the object.
#
# Parameters:
#	 $dbi:        the dbi object
#	 $statements: the statements to execute
#	 $type:       the type of object to add (variety, attribute, etc)
#	 $lookup:     the field used to find the object, 
#	              this field is also inserted in the database
#	              if needed
#	 @other:      extra data that will be insterted if needed
#
sub add_object {
	
	my ($dbi, $statements, $type, $lookup, @others) = @_;
	
	DEBUG("Looking up $type: $lookup");
	
	# Get the producer id
	if (my $row = find_id($statements->{$type}{select}, $lookup)) {
		# Found the object
		my $id = $row->{"${type}_id"};
		DEBUG("Found $type $lookup, using id $id");
		
		return $id;
	}


	# Insert the producer in the database
	$statements->{$type}{insert}->execute($lookup, @others);
		
	# Get the last id inserted
	my $table = PL($type);
	my $field = "${type}_id";
	my$id = $dbi->last_insert_id(undef, undef, $table, $field);
		
	INFO("Added $type ", format_values($lookup, @others), " and got id $id");
	
	return $id;
}


#
#
#Finds the id of the given object by executing the given statement.
#
sub find_id {

	my ($statement, @bind) = @_;
	
	# Find the data
	DEBUG("Looking for (", join(", ", @bind), ")");
	$statement->execute(@bind);
	my $row = $statement->fetchrow_hashref('NAME_lc');
	
	# If the object can't be found return undef
	if (! defined $row) {
		DEBUG("Object @bind not found");
		return undef;
	}
	
	# Check that there is only one entry
	if (defined $statement->fetchrow_hashref('NAME_lc')) {
		ERROR("More than one row for @bind");
	}
	
	DEBUG("Found object ", format_values(values %{$row}));
	
	return $row;
}


#
# Formats the values of a list, used only for debug purposes
#
sub format_values {
	
	my (@values) = map { defined $_ ? sprintf q{"%s"}, $_ : 'NULL' } @_;
	
	my $string = join(', ', @values);

	return "($string)";
}
