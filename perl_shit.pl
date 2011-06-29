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
 $shit{hex $line} = [ $mult, $zahl]; 
 $pos++;
}
close ($fh);


while(my $foobar = <STDIN>)
{
  chomp $foobar;
  print join "\t",$foobar , $shit{hex $foobar}[0],$shit{hex $foobar}[1],"\n";


}
