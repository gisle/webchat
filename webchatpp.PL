use Config qw(%Config);
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';

use strict;
use Config qw(%Config);

my $progname = $0;
$progname =~ s,.*/,,; # loose path

my $file;
if (!@ARGV) {
    $file = "<stdin>";
    *F = *STDIN;
} elsif (@ARGV == 1) {
    $file = shift;
    open(F, $file) || die "Can't open '$file': $!\n";
} else {
    usage();
}

print "$Config{'startperl'} -w\n";

print "# !!! DO NOT EDIT !!!\n";
print "# This program was automatically generated from '$file' by $progname\n";

print <<'EOT';

use strict;

use URI ();
use HTTP::Request ();
use LWP::UserAgent ();
#use LWP::Debug qw(+);

use HTML::Form ();
use WWW::Chat qw(fail OK ERROR);

use vars qw($ua $uri $base $req $res $status $ct @forms $form @links $TRACE);

$base ||= "http://localhost";
unless ($ua) {
    $ua  = LWP::UserAgent->new;
    $ua->agent("webchat/0.01 " . $ua->agent);
    $ua->env_proxy;
}

$TRACE = $ENV{WEBCHAT_TRACE};

EOT

print "#line 1 \"$file\"\n";

use Data::Dump qw(dump);

my $seen_end;
my $level = 0;

while (<F>) {
    if ($seen_end) {
	print;
	next;
    }

    if (/^(\s*)GET\s+(\S+)\s*$/) {
	my $indent = $1;
	my $uri = $2;
	$uri = dump($uri) unless $uri =~ /^\$/;
	print "$indent#GET $uri\n";
	print "${indent}eval {\n";
	$level++;
        print "$indent    local \$uri = URI->new_abs($uri, \$base);\n";
	print "$indent    local \$req = HTTP::Request->new(GET => \$uri);\n";
	request("$indent    ");
	line();

    } elsif (/^(\s*)FOLLOW\s(.*)/) {
	my $indent = $1;
	my $what = $2;
	$what =~ s/\s+$//;
	print "${indent}# FOLLOW $what\n";
	print "${indent}eval {\n";
	$level++;
	if ($what =~ m,^/,) {
	    print "$indent    local \$uri;\n";
	    print "$indent    for (\@links) { \$uri = \$_->[0], last if \$_->[1] =~ $what }\n";
	    my $text = dump("FOLLOW $what");
	    print "$indent    fail($text) unless defined \$uri;\n";
	    print "$indent    \$uri = URI->new_abs(\$uri, \$base);\n";
	} else {
	    $what = dump($what);
	    print "$indent    local \$uri = WWW::Chat::locate_link($what, \\\@links, \$base);\n";
	}
	print "$indent    local \$req = HTTP::Request->new(GET => \$uri);\n";
	request("$indent    ");
	line();

    } elsif (/^(\s*)FORM:?(\d+)?(?:\s+(\S+))?\s*$/) {
	my $indent = $1;
	my $form_no = $2 || 1;
        my $uri = $3;
	$uri = dump($uri) if !defined($uri) || $uri !~ /^\$/;
	print $indent, "\$form = WWW::Chat::findform(\\\@forms, $form_no, $uri);\n";

    } elsif (/^(\s*)EXPECT\s+(.*)$/) {
	my $indent = $1;
	my $what = $2;
	$what =~ s/;$//;
	#print "$indent#EXPECT $what\n";
	my $text = dump($what);
	print $indent, "fail($text) unless $what;\n";

    } elsif (/^(\s*)BACK(?:\s+(ALL|\d+))?\s*$/) {
	my $indent = $1;
	my $done = $2 || "1";
	done($indent, $done);
	
    } elsif (/^(\s*)F\s+([\w.:\-*\#]+)\s*=\s*(.*)/) {
	my $indent = $1;
	my $name   = $2;
	my $val    = dump("$3");

	my $no = 1;
	$no = $1 if $name =~ s/:(\d+)$//;
	$name = dump($name);

	if ($no == 1) {
	    print "$indent\$form->value($name => $val);\n";
	} else {
	    print "$indent\$form->find_input($name, $no)->value($val);\n";
	}

    } elsif (/^(\s*)(?:CLICK|SUMBIT)(?:\s+(\w+))?(?:(\d+)\s+(\d+))?/) {
	my $indent = $1;
	my $name = $2;
	$name = dump($name);
	my $x = $3;
	my $y = $4;
	for ($x, $y) { $_ = 1 unless defined; }
	print "$indent#CLICK $name $x $y\n";
	print $indent, "eval {\n";
	$level++;
	print $indent, "    local \$uri = \$form->uri;\n";
	print $indent, "    local \$req = \$form->click($name, $x, $y);\n";
	request("$indent    ");
	line();

    } elsif (/^__END__$/) {
	done("", "ALL") if $level;
	print;
	$seen_end++;

    } else {
	print;
    }
}
done("", "ALL") if $level;
exit;


sub usage
{
    die "Usage: $progname [<file>]\n";
}

sub done
{
    my($indent, $done) = @_;
    $done = $level if $done eq "ALL" || $done > $level;
    $level -= $done;
    for (1 .. $done) {
	print $indent, "}; WWW::Chat::check_eval(\$@);\n";
    }
    line() if $done > 1;
}

sub request
{
    my $indent = shift;
    print $indent, "local \$res = WWW::Chat::request(\$req);\n";
    print $indent, "#print STDERR \$res->as_string;\n";
    print $indent, "local \$status = \$res->code;\n";
    print $indent, "local \$base = \$res->base;\n";
    print $indent, "local \$ct = \$res->content_type || \"\";\n";
    print $indent, "local \$_ = \$res->content;\n";
    print $indent, "local(\@forms, \$form, \@links);\n";
    print $indent, "if (\$ct eq 'text/html') {\n";
    print $indent, "    \@forms = HTML::Form->parse(\$_, \$res->base);\n";
    print $indent, "    \$form = \$forms[0] if \@forms;\n";
    print $indent, "    \@links = WWW::Chat::extract_links(\$_);\n";
    print $indent, "}\n";
}

sub line
{
    my $line = $. + 1;
    print qq(#line $line "$file"\n);
}

__END__

=head1 NAME

webchatpp - Preprocessor for Web Chat scripts

=head1 SYNOPSIS

 webchatpp chat-script | perl

=head1 DESCRIPTION

The C<webchatpp> program is a preprocessor that turns chat scripts
into plain perl scripts.  When this script is feed to perl it will
perform the chatting.  The I<webchat language> consist of perl code
with some lines interpreted and expanded by I<webchatpp>.  The
following statements are recognized:

=over 4

=item GET <uri>

This will fetch the indicated URI.  The URI can be relative to the
previous base.  Each GET gets it's own eval block within the perl
program to catch any exceptions.  Inside this block, the following
dynamically scoped variables are available:

  $uri       The current URI
  $req       The current request object        [HTTP::Request]
  $res       The response received             [HTTP::Response]
  $status    The status code of the response
  $ct        The content type of the response
  $base      The base URI for current response
  $_         The content of the response
  @forms     Forms found in current content    [HTML::Form]
  $form      Current form                      [HTML::Form]
  @links     Links found in current content

=item EXPECT <expr>

Evaluate the perl expression <expr> and report failure if it does not
return TRUE.  The fact that content of the response is available in $_
makes it easy to match it with regular expressions.  The routines OK()
and ERROR() is available to test the response status code.

When EXPECT fails all tests nested within this one is aborted too.

=item FORM[:<no>] [<name>]

Define which <FORM> should be the current one.  Sets the C<$form>
variable.  If no number is specified, then number 1 is assumed.  If a
form with the given number (or name, if specified) can not be found,
then an exception is raised, and this block is aborted.

=item F <name>=<value>

Set input values within the current form.  If the current form has no
field named <name>, then an exception is raised.  If the form has
multiple fields named <name>, then only the first one is affected.

=item CLICK [<name>] [<x> <y>]

Submit a <form>.  If there are multiple submit buttons, then you can
specify which one by passing the <name>.  You can also indicate which
coordinates within the buttion, was clicked.  Only makes a difference
for C<input/image> submits.

CLICK enters a new block similar to GET, and make the same dynamically
scoped variables available.

You can use the keyword "SUBMIT" instead of "CLICK" if you prefer.  It
is a plain alias.

=item FOLLOW /text/

Tries to find a hyperlink with the given description, and will then
follow it.  Enters a new block like GET.

=item FOLLOW <num>

Will follow the <num>'th hyperlink on the current page.  Enters a new
block like GET.

=item BACK [<levels> | "ALL"]

Ends the previous GET or CLICK blocks.  The argument can be used to
get out of multiple blocks.

=item _END__

Stop looking for I<webchat language> directives.  The rest of the
script is dumped directly (and is also ignored by perl).  Implies
"C<BACK ALL>".

=back

The following variables are global within the whole web chat script
produced:

  $ua        User agent object    [LWP::UserAgent]
  $uri       Current URI
  $TRACE     Print trace showing HTTP requests/responses.

=head1 ENVIRONMENT

The initial value of the $TRACE variable is initialized from the
WEBCHAT_TRACE environment variable.

Proxy settings are picked up from the environment too. See
L<LWP::UserAgent/env_proxy>.

=head1 EXAMPLES

This is a sample script:

 GET http://www.perl.com
    EXPECT OK && /perl/
    GET not_there.html
       EXPECT ERROR
    BACK
 BACK

And here is another one

 GET http://www.altavista.com
 EXPECT OK
 F q=Gisle
 CLICK
 EXPECT OK && /Gisle Aas/

=head1 SEE ALSO

L<LWP>, L<HTML::Form>

=head1 COPYRIGHT

Copyright 1998 Gisle Aas.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
!NO!SUBS!
