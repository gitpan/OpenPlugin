package OpenPlugin::Request;

# $Id: Request.pm,v 1.4 2002/10/08 19:07:15 andreychek Exp $

use strict;
use base qw( OpenPlugin::Plugin );

$OpenPlugin::Request::VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'request' }

sub object { };
sub uri    { };


1;

__END__

=pod

=head1 NAME

OpenPlugin::Request - Retrieve values related to the client request

=head1 SYNOPSIS

 my $r = shift;
 $OP = OpenPlugin->new( request => { apache => $r });

 ...

 my $req_obj = $OP->request->object;
 my $uri     = $OP->request->uri;

=head1 DESCRIPTION

The Request plugin offers an interface to retrieve various pieces of
information available regarding the client request.

If you're looking for methods to work with L<params|OpenPlugin::Param>,
L<cookies|OpenPlugin::Cookie>, L<headers|OpenPlugin::HttpHeader>, or
L<uploads|OpenPlugin::Upload>, so those respective plugins.

This plugin acts as somewhat of a superclass of those plugins, and offers you
access to the request object, along with a variety of other methods.

=head1 METHODS

B<object()>

Returns the request object.

B<uri()>

Returns the uri for the last request.

=head1 BUGS

None known.

=head1 TO DO

The interface provided by the Request/Cookie/Httpheader/Param/Upload plugins,
is, as you know, meant to abstract the existing CGI and mod_perl interfaces
(along with any other drivers that may, at one day, be created).  The interface
provided here is certainly not complete.  What other functionality should we
provide here?

Another thing we are doing now is allowing, say, the httpheader plugin to use
the CGI driver, and the param plugin the Apache driver.  Is this useful?  Some
things could be made simpler both internally and externally if we eliminate
that possibility, and have httpheader/param/cookie/upload all use the same
driver.

To allow for more flexibility, I'm looking at adding some functionality to
functions provided by these modules.  Instead of requiring that you use
get_incoming/set_incoming, I'm looking at making an incoming method, which gets
or sets based on how many parameters it was passed.

I'm also considering providing a mechanism for retrieving a tied hash.  Instead
of using the above interface, you would just add or remove items from the tied
hash.  Very similar to Apache::Table.

It would be neat to have more drivers.  How about a L<POE> driver?
L<CGI::Request>, L<CGI::Base>, L<CGI::MiniSvr>, and others would also be neat.

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2002 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
