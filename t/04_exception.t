#!/usr/bin/perl

# $Id: 04_exception.t,v 1.2 2002/10/12 04:00:21 andreychek Exp $

use strict;
use Test::More  tests => 5;

use lib "./t";
use OpenPluginTests( "get_config" );
use OpenPlugin();

my $data = get_config( "exception", "log_log4perl" );
my $OP = OpenPlugin->new( config => { data => $data });

eval { $OP->exception->throw("Test Exception Thrown: ",
                             "Exceptional test! (ok)"); };
# Test 1: Throw Exception
{

    ok( $@, "Exception thrown" );
}

# Test 2: Check OpenPlugin::Exception Object
{
    ok( ref $@ eq "OpenPlugin::Exception",
                  "Make \$@ OpenPlugin::Exception Object" );
}

# Test 3: Check Exception Field Names
{
    my @fields = $@->get_fields();
    my $fields = join " ", sort @fields;
    ok( $fields eq "filename line message method package trace",
                   "Retrieve Field Names");
}

# Test 4: Check Error Stack
{
    my @stack = $@->get_stack();
    ok( "$stack[0]" eq "Test Exception Thrown: Exceptional test! (ok)",
        "Retrieve Error Stack" );
}

# Test 5: Clear Error Stack
{
    my @stack = $@->clear_stack();
    ok( "$stack[0]" eq "", "Clear Error Stack" );
}
