#!/usr/bin/env perl
# doplnek pro skript pocty-bytu-na-adrese.sh

use XML::Parser;
use Data::Dumper;

$p2 = XML::Parser->new(Handlers => {Start => \&handle_start,
                                   End   => \&handle_end,
                                   Char  => \&handle_char,
                                   });
$p2->parse(STDIN);
exit;

our @heap;
our %objekt = undef;
our $devnull;
our $write_pointer;

sub handle_start
{
  shift;
  my $el = shift;
  push @heap, $el;

  if ($el eq 'vf:StavebniObjekt')
  {
    undef %objekt;
    my $objid = @_[1];
    $objid =~ s/^SO\.//; # "SO.95195645" -> "95195645"
    $objekt{id} = $objid;
  }
  $write_pointer = \$objekt{CisloDomovni} if $el eq 'com:CisloDomovni';
  $write_pointer = \$objekt{PocetBytu} if $el eq 'soi:PocetBytu';
}

sub handle_end
{
  shift;
  my $el = shift;
  if ($el eq 'vf:StavebniObjekt')
  {
    if (defined $objekt{PocetBytu})
    {
      printf "%u,%u\n", $objekt{id},$objekt{PocetBytu}
    }
  }

  $write_pointer = \$devnull;
  pop @heap;
}

sub handle_char
{
  $$write_pointer = $_[1];
}
