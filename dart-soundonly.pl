#!/usr/bin/perl -T -w
use strict;
$ENV{PATH}='';
$| = 1;
&main();
exit 0;

sub main
{
  while (my $schuss = <STDIN>)
  {
    chomp $schuss;
		
    my ($mult,$zahl)=split /\s+/,$schuss or next;

    if ($mult eq "btn") {
      print "player\n";
      next;
    } elsif (not $mult =~ /^\d+$/) {
      print "$mult\n";
      next;
    } elsif ($mult==2) {
      print "double\n";
    } elsif ($mult==3) {
      print "triple\n";
    } 
    if (not $zahl =~ m/\d+/)
    {
      print STDERR "Unexpected input $zahl\n";
      next;
    }
    ($zahl) = $zahl =~ m/(\d+)/;
    if ($zahl >0 && $zahl < 21)
    {
      print $zahl . "\n";
    } else {
      print "bull\n";
    }
  } 
}

