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
our %adresniMisto = undef;
our $devnull;
our $write_pointer;

sub handle_start
{
  shift;
  my $el = shift;
  push @heap, $el;

  if ($el eq 'vf:AdresniMisto')
  {
    undef %adresniMisto;
    my $objid = @_[1];
    $objid =~ s/^AD\.//; # "AD.30474477" -> 30474477
    $adresniMisto{id} = $objid;
  }
  $write_pointer = \$adresniMisto{ObjektKod} if $el eq 'soi:Kod';
  $write_pointer = \$adresniMisto{UliceKod} if $el eq 'uli:Kod';
}

sub handle_end
{
  shift;
  my $el = shift;

  if ($el eq 'vf:AdresniMisto')
  {
    printf "%u,%u\n", $adresniMisto{id}, $adresniMisto{ObjektKod};
  }

  $write_pointer = \$devnull;
  pop @heap;
}

sub handle_char
{
  $$write_pointer = $_[1];
}
