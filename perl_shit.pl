#!/usr/bin/perl
my $pos=0;
my %shit;
for (0..63)
{
  $shit{$_}=['nc','nc'];
}
print "Reading ".$ARGV[0]."\n";
open(my $fh, '<', $ARGV[0]) ;

while( my $line =<$fh>)
{
 chomp $line;
 my $zahl = (int($pos / 3)) +1 ;
 my $mult =( $pos % 3 )+1;
 $zahl = 25 if $zahl == 21;
 $shit{hex $line} = [ $mult, $zahl]; 
 $pos++;
}
close ($fh);

for my $foobar ( sort { $a <=> $b } keys %shit)
{
  
  print sprintf "%d,", $shit{$foobar}[0]<<5|$shit{$foobar}[1];
}

while(my $foobar = <STDIN>)
{
  chomp $foobar;
  print join "\t",$foobar , $shit{hex $foobar}[0],$shit{hex $foobar}[1],"\n";

}
