package OpenPlugin::Exception;

# $Id: Exception.pm,v 1.23 2002/10/09 02:59:30 andreychek Exp $

use strict;
use base                  qw( OpenPlugin::Plugin );
#use overload              q("") => \&stringify;
use overload '""' => sub { $_[0]->to_string };
use Devel::StackTrace();

$OpenPlugin::Exception::VERSION = sprintf("%d.%02d", q$Revision: 1.23 $ =~ /(\d+)\.(\d+)/);

my @STACK  = ();
my @FIELDS = qw( message package filename line method trace );

sub type { return 'exception' }
sub OP   { return $_[0]->{_m}{OP} }


########################################
# CLASS METHODS

sub throw {
    my ( $self, @message ) = @_;

    my $class = ref( $self ) || $self;

    my $params = ( ref $message[-1] eq 'HASH' )
                   ? pop( @message ) : {};

    my $msg    = join( '', @message );

    # Set a default in case throw is called without a value
    $msg ||= "An unknown error has occurred.";

    foreach my $field ( $self->get_fields() ) {
        $self->state( $field, $params->{ $field } ) if ( $params->{ $field } );
    }

    # Now do the message and the initial trace stuff

    $self->state( 'message', $msg );

    my @initial_call = caller;
    $self->state( 'package',  $initial_call[0] );
    $self->state( 'filename', $initial_call[1] );
    $self->state( 'line',     $initial_call[2] );

    # Grab the method name separately, since the subroutine call
    # doesn't seem to be matched up properly with the other caller()
    # stuff when we do caller(0). Weird.

    my @added_call = caller(1);
    $added_call[3] =~ s/^.*:://;
    $self->state( 'method', $added_call[3] );

    $self->state( 'trace', Devel::StackTrace->new());

    $self->initialize( $params );

    push @STACK, $self;

    $self->OP->log->fatal( $self->state->{ message } );

    die $self;

}

sub initialize {}

sub get_fields  { return @FIELDS }

sub get_stack   { return @STACK }
sub clear_stack { @STACK = ()   }

#sub trace       { return $_[0]->state->{ trace } };

########################################
# OBJECT METHODS

sub creation_location {
    my ( $self ) = @_;
    return 'Created in package [' . $self->state->{ package }  . '] ' .
                    'in method [' . $self->state->{ method }   . ']; '.
                      'at file [' . $self->state->{ filename } . '] ' .
                      'at line [' . $self->state->{ line }     . ']';
}

sub stringify   { return $_[0]->to_string() }
sub to_string   {
    my ( $self ) = @_;
    my $class = ref $self;

    return "Invalid -- not called from object." unless ( $class );

    # Give everything back if it doesn't look like we were meant to be called
    unless (( $self->state ) && ( $self->state->{ message } )) {
        return @_;
    }

    #no strict 'refs';
    return $self->state->{ message }; #unless ( ${ $class . '::ShowTrace' } );

    #return join( "\n", $_[0]->state->{message}, $_[0]->trace );
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Exception - Base class for exceptions in OpenPlugin

=head1 SYNOPSIS

 # As a user of a module developed using OpenPlugin

 eval { $OP->session->save( $session ) };
 if ( $@ ) {
    print "Error: $@", $@->creation_location, "\n";
 }

 # Or, get a stack trace

 eval { $OP->session->save( $session ) };
 if ( $@ ) {
    print "Error: $@",
          "Stack trace: ", $@->trace->as_string, "\n";
 }

 # Get all exceptions (including from subclasses that don't override
 # throw()) since the stack was last cleared

 my @errors = $OP->exception->get_stack;
 print "Errors found:\n";
 foreach my $e ( @errors ) {
    print "ERROR: ", $e->creation_location, "\n";
 }

 # As a developer of a module which uses OpenPlugin

 my $rv = eval { $dbh->do( $sql ) };
 if ( $@ ) {
     $@->throw( "There was an error! $@" );
 }

 # Throw an exception that subclasses OpenPlugin::Exception with extra
 # fields

 my $rv = eval { $dbh->do( $sql ) };
 if ( $@ ) {
     $OP->exception->DBI->throw( $@, { sql    => $sql,
                                       action => 'do' } );
 }

=head1 DESCRIPTION

This class is the base for all exceptions in OpenPlugin. An exception is
generally used to indicate some sort of error condition rather than a
situation that might normally be encountered. For instance, you would
not throw an exception if you tried to C<fetch()> a record not in a
datastore. But you would throw an exception if the query failed
because the database schema was changed and the SQL statement referred
to removed fields.

You can easily create new classes of exceptions if you like, see
L<SUBCLASSING> below.

=head1 METHODS

B<throw( $message, [ \%params ] )>

This is the main action method and often the only one you will use. It creates
a new exception object and calls C<die> with the object. Before calling C<die>
with it it first does the following:

=over 4

=item 1. We check C<\%params> for any parameters matching fieldnames
returned by C<get_fields()>, and if found set the field in the object
to the parameter.

=item 2. Fill the object with the relevant calling information:
C<package>, C<filename>, C<line>, C<method>.

=item 3. Set the C<trace> property of the object to a
L<Devel::StackTrace|Devel::StackTrace> object.

=item 4. Call C<initialize()> so that subclasses can do any object
initialization/tracking they need to do. (See L<SUBCLASSING> below.)

=item 5. Track the object in our internal stack.

=back

B<get_stack()>

Returns a list of exceptions that had been put on the stack.  This can be
particularly useful when there are multiple errors thrown during the execution
of your program, and you want to get information regarding each one.

 my @errors = $OP->exception->get_stack;
 print "Errors found:\n";
 foreach my $e ( @errors ) {
    print "ERROR: ", $e->creation_location, "\n";
 }

Instead of B<$e->creation_location>, which gives you several pieces of
information about each error, you can get individual pieces of information
using the following individual methods:

 print $e->state->{ message };
 print $e->state->{ package };
 print $e->state->{ filename };
 print $e->state->{ line };

B<get_fields()>

Returns a list of property names used for this class. If a subclass
wants to add properties to the base exception object, the common idiom
is:

 my @FIELDS = qw( this that );
 sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

So that all fields are represented.

B<creation_location>

Returns a string with information about where the exception was
thrown. It looks like (all on one line):

 Created in [%package%] in method [%method%];
 at file [%filename%] at line [%line%]

=head1 PROPERTIES

The following properties are default properties of an OpenPlugin::Exception
object.  Don't forget that one can add to this property list by subclassing
this module.  These properties can be accessed using:

  $exception_object->state->{ $property_name };

B<message>

This is the message the exception is created with -- there should be
one with every exception. (It is bad form to throw an exception with
no message.)

B<package>

The package the exception was thrown from.

B<filename>

The file the exception was thrown from.

B<line>

The line number in C<filename> the exception was thrown from.

B<method>

The subroutine the exception was thrown from.

B<trace>

Returns a L<Devel::StackTrace|Devel::StackTrace> object, which had been created
at the point where the exception was thrown.

 $@->state->{ trace }->as_string;

=head1 SUBCLASSING

It is very easy to create your own OpenPlugin or application errors:

 package My::Custom::Exception;

 use strict;
 use base qw( OpenPlugin::Exception );

Easy! If you want to include different information that can be passed
via C<new()>:

 package My::Custom::Exception;

 use strict;
 use base qw( OpenPlugin::Exception );
 my @FIELDS = qw( this that );
 My::Custom::Exception->mk_accessors( @FIELDS );

 sub get_fields { return ( $_[0]->SUPER::get_fields(), @FIELDS ) }

And now your custom exception can take extra parameters:

 $self->My::Custom::Exception->throw( $@, { this => 'bermuda shorts',
                                            that => 'teva sandals'    });

If you want to do extra initialization, data checking or whatnot, just
create a method C<initialize()>. It gets called just before the C<die>
is called in C<throw()>. Example:

 package My::Custom::Exception;

 # ... as above

 my $COUNT = 0;
 sub initialize {
     my ( $self, $params ) = @_;
     $COUNT++;
     if ( $COUNT > 5 ) {
         $self->message(
               $self->message . "-- More than five errors?! ($COUNT) Whattsamatta?" );
     }
 }

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<Devel::StackTrace|Devel::StackTrace>

L<Exception::Class|Exception::Class> for lots of good ideas.

L<SPOPS::Exception|SPOPS::Exception>

Copyright (c) 2001-2002 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

Chris Winters <chris@cwinters.com>

=cut

