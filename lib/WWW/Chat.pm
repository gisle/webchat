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

sub extract_links
{
    require HTML::TokeParser;
    my $p = HTML::TokeParser->new(\$_[0]);
    my @links;

    while (my $token = $p->get_tag("a")) {
	my $url = $token->[1]{href};
	next unless defined $url;   # probably just a name link
	my $text = $p->get_trimmed_text("/a");
	push(@links, [$url => $text]);
    }
    return @links;
}

sub locate_link
{
    my($where, $links, $base) = @_;
    my $no_links = @$links;
    Carp::croak("Only $no_links links on this page ($where)") if $where >= $no_links;
    require URI;
    URI->new_abs($links->[$where][0], $base);
}

1;
