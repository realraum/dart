#!/usr/bin/perl
use strict;
use POSIX;
use Term::Cap;
# General terminal line I/O
my $termios = new POSIX::Termios;
$termios->getattr;
my $term = Term::Cap->Tgetent( { OSPEED => $termios->getospeed } );



# Extract the entry of the terminal type

# clear

my (@player) = @ARGV;

my $numplayer = @player;
my $round =0;
my %score;
my $unlock=6;
my $unlock_mult=1;
my $current_player=1;
my $last_shot=6;
my $last_shot_mult=1;
while ( my $schuss = <STDIN>)
{
  print $schuss;
	my ($mult,$zahl) = split /\s+/, $schuss;
   
  if ($mult =~/^\d$/)
	{
 $last_shot=$zahl;
 $last_shot_mult=$mult;
		if ($unlock == $zahl && $unlock_mult== $mult)
		{
			$unlock =0;
			$unlock_mult=0;
		}
	  if($zahl >14 && $zahl <21 && ! $unlock)
		{
			while($mult--)
			{
				if ($score{$current_player}{$zahl}<3)
				{
					$score{$current_player}{$zahl}++;
				} else {
					for my $playernum (1..$numplayer)
					{
						if ($score{$playernum}{$zahl}<3)
						{
							$score{$playernum}{0}+=$zahl;
							print "score\n";
						}
					}
				}
			}
		}
	} else {
    $current_player++;
    $round++ if $current_player > $numplayer;
    $current_player=1 if $current_player > $numplayer;
		if (!$unlock)
		{
		  $unlock=$last_shot;
		  $unlock_mult=$last_shot_mult;
			}
	}
	print_score($schuss);
}



sub print_score
{
 my ($schuss) =@_;
# $term->Tputs('cl', 1, <STDERR>);
 printf STDERR "\n\n";
 printf STDERR "$schuss $unlock_mult x $unlock Runde\t$round\n\n";
				for my $playernum (1..$numplayer)
				{

								printf STDERR "%s\t", ($playernum == $current_player)?"(".$player[$playernum-1].")":$player[$playernum-1];
				}
				print STDERR "\n";
				for my $i (15..20)
				{
								for my $playernum (1..$numplayer)
								{
												my $zahl = $i>20?25:$i;
												printf STDERR ("%2d %s    ",$zahl, '#' x $score{$playernum}{$zahl}. '-' x (3-$score{$playernum}{$zahl}));
								}
								print STDERR "\n";
				}
				for my $playernum (1..$numplayer)
				{

								printf STDERR ("%3d\t", $score{$playernum}{0});
				}
}
