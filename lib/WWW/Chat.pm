package WWW::Chat;

use strict;
require Exporter;
*import = \&Exporter::import;
use vars qw(@EXPORT_OK);
@EXPORT_OK=qw(fail OK ERROR);

use Carp ();

sub fail
{
    my $reason = shift;
    Carp::carp("FAILED $reason");

    # Print current response too...
    my $res = $main::res->clone;
    my $cref = $res->content_ref;
    if ($main::ct =~ m,^text/,) {
	substr($$cref, 256) = "..." if length($$cref) > 512;
    } else {
	$$cref = "";
    }
    $res = $res->as_string;
    $res =~ s/^/  /gm;
    print STDERR $res;

    die "ASSERT";
}

sub check_eval
{
    return unless $_[0];
    return if $_[0] =~ /^ASSERT /;
    print STDERR $_[0];
}


sub OK
{
    $main::status == 200;
}

sub ERROR
{
    $main::status >= 400 && $main::status < 600;
}

sub request
{
    my $req = shift;
    print STDERR ">> " . $req->method . " " . $req->uri . " ==> "
	if $main::TRACE;
    #print STDERR "\nCC " . $req->content . "\n" if $main::TRACE;
    my $res = $main::ua->request($req);
    print STDERR $res->status_line . "\n"
	if $main::TRACE;
    $res;
}

sub findform
{
    my($forms, $no, $uri) = @_;
    my $f = $forms->[$no-1];
    Carp::croak("No FORM number $no") unless $f;
    my $furi = $f->uri;
    Carp::croak("Wrong FROM name ($furi)") if $uri && $furi !~ /$uri$/;
    $f;
}

1;
