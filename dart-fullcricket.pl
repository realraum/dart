#!/usr/bin/perl
use strict;
#use POSIX;
#use Term::Cap;
# General terminal line I/O
#my $termios = new POSIX::Termios;
#$termios->getattr;
#my $term = Term::Cap->Tgetent( { OSPEED => $termios->getospeed } );
my $sieb=0;
my @prim = qw / 2 3 5 7 11 13 17 19 /;

sub gueltig{
    my ($zahl,$mult) = @_;
    return 1;
  };


$|=1;

# Extract the entry of the terminal type

# clear

my (@player) = @ARGV;

my $numplayer = @player;
my $round =0;
my %score;
my $current_player=1;
while ( my $schuss = <STDIN>)
{
  #print STDERR $schuss;
  my ($mult,$zahl) = split /\s+/, $schuss;

  if ($mult =~/^\d$/)
  {
    if (not gueltig($zahl,$mult))
    {
      print "miss\n";
      next;
    }
    my ($scho,$scored,$self_scored);
    while($mult--)
    {

      if ($score{$current_player}{$zahl}<3)
      {
        $score{$current_player}{$zahl}++;
        $self_scored++;
        if ($sieb && ($score{$current_player}{$zahl} == 3))
        {
          for my $count (2..21)
          {
            $count = 25 if $count ==21;
            if ( ($count % $zahl) == 0)
            {
              $score{$current_player}{$count} = 3;
            }
          }
        }
      } else {
        $scho++;
        for my $playernum (1..$numplayer)
        {
          if ($score{$playernum}{$zahl}<3)
          {
            $score{$playernum}{0}+=$zahl;
            $scored++;
          }
        }
      }
    }
    print $schuss if ($scored || $self_scored);
    print "scored\n" if $scored;
    print "scho\n" if $scho && not $scored;
  } elsif ($mult eq 'btn') {
    print $schuss;
    $current_player++;
    $round++ if $current_player > $numplayer;
    $current_player=1 if $current_player > $numplayer;
    # print "player\n";
    print $player[$current_player-1]."\n";
  }
  print_score($schuss);
}



sub print_score
{
  my ($schuss) =@_;
# $term->Tputs('cl', 1, <STDERR>);
  printf STDERR "\n\n";
  printf STDERR "$schuss Runde\t$round\n\n";
  for my $playernum (1..$numplayer)
  {

    printf STDERR "%s\t", ($playernum == $current_player)?"(".$player[$playernum-1].")":$player[$playernum-1];
  }
  print STDERR "\n";
  for my $i (1..21)
  {
    for my $playernum (1..$numplayer)
    {
      my $zahl = $i>20?25:$i;
      next if not gueltig($zahl);
      printf STDERR ("%2d %s    ",$zahl, '#' x $score{$playernum}{$zahl}. '-' x (3-$score{$playernum}{$zahl}));
    }
    print STDERR "\n";
  }
  for my $playernum (1..$numplayer)
  {

    printf STDERR ("%3d\t", $score{$playernum}{0});
  }
}
