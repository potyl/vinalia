#!/usr/bin/perl

use strict;
use warnings;

# GTK 2 stuff
use Glib qw/TRUE FALSE/;
use Gtk2;
use Gtk2::GladeXML;
use Gtk2::SimpleList;

use Template;
use DBI;
use Encode;
use FindBin;



# Create accessors
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors( qw(glade dbi template) );
 
use Data::Dumper;


# Start the main function
exit main();



sub main {
	
	Gtk2->init;
	
	# Create a GUI based on glade
	my $vinalia = __PACKAGE__->new("$FindBin::Bin/template-gui.glade");
	
	# Start the main loop
	Gtk2->main;
	
	return 0;
}


#
# Creates a new instance of the application
#
# Parameters:
#  $glade_file: The glade file to load
#
sub new {
	
	my $class = shift;
	my ($glade_file) = @_;
	
	my $self = bless {}, ref($class) || $class;
	
	$self->glade(Gtk2::GladeXML->new($glade_file));
	$self->glade->signal_autoconnect_from_package($self);

	# Create a database connection
	$self->{dbi} = DBI->connect(
		"dbi:Pg:dbname=vinalia;host=127.0.0.1", 
		"vinalia", 
		"vino", 
		{
			AutoCommit => 1,
			RaiseError => 1,
		}
	);

	# Create a reference to the template engine
	$self->{template} = Template->new(
		{
			EVAL_PERL    => 1,
			INTERPOLATE  => 1, 
			
			ABSOLUTE     => 1,
			CACHE_SIZE   => 0,
			
			VARIABLES => {
				SQL => sub { $self->do_select(@_) },
				format => sub { sprintf "%.2f", @_ },
			},
		}
	);
	
	# Set a default text in the template widget
	$self->glade->get_widget('textview-template')->get_buffer->set_text(<<'__TEMPLATE__');
[%- FOR row IN SQL("SELECT * FROM wines_summary") -%]

	[%- row.variety %] 	[% format(row.year) -%]

[% END -%]
__TEMPLATE__

	return $self;
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



##
# Callbacks
##


#
# Apply the template
#

sub on_action_submit {
	my $self = shift;
	
	
	
	# Get the template text
	my $buffer = $self->glade->get_widget('textview-template')->get_buffer;
	my $template = $buffer->get_text($buffer->get_start_iter, $buffer->get_end_iter, FALSE);

	# Apply the template
	my $text = "";
	my $success = undef;
	

	eval {
		$success = $self->template->process(\$template, undef, \$text);
	};
	if (my $error = $@) {
		$text = "Failed to apply template because: $error";
	}
	if (! $success) {
		$text = "Template failed because: " . $self->template->error;
	}
	
	$self->glade->get_widget('textview-results')->get_buffer->set_text($text);
}


#
# Close the application
#
sub on_main_window_quit {
	Gtk2->main_quit;
}

