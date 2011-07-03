#!/usr/bin/perl
# use strict;
use Dart;



$|=1;
my (@player) = @ARGV;

my $dart = new Dart(player_names=>\@player, 
                    callbacks => {
                      shoot=>\&shoot,   
                      next_player=>\&next_player,
                    }
                  );
exit $dart->run(STDIN,STDOUT);

### ===============================

my $sieb =1; # Spielmodus Zahlensieb
sub gueltig
{
  my ($zahl,$mult) = @_;
  return $zahl>1;
}

sub shoot
{
  my $self=shift;
  my ($mult,$zahl)=@_;
  $self->get_current_player()->{score} = {} if not $self->get_current_player()->{score};
  my $score=$self->get_current_player()->{score};

  if (not gueltig($zahl,$mult))
  {
    $self->shout("miss");
    return;
  }
  my ($scho,$scored,$self_scored);
  while($mult--)
  {

    if ($score->{$zahl}<3)
    {
      $score->{$zahl}++;
      $self_scored++;
      if ($sieb && ($score->{$zahl} == 3))
      {
        for my $count (2..21)
        {
          $count = 25 if $count ==21;
          if ( ($count % $zahl) == 0)
          {
            $score->{$count} = 3;
          }
        }
      }
    } else {
      $scho++;
      for my $player_idx (0..($self->{player_count}-1))
      {
        next if not $self->get_player($player_idx)->{active};
        if ($self->get_player($player_idx)->{score}->{$zahl}<3)
        {
          $self->get_player($player_idx)->{score}->{0}+=$zahl;
          $scored++;
        }
      }
    }
  }
  $self->shout_last_shoot() if ($scored || $self_scored);
  $self->shout("scored") if $scored;
  $self->shout("scho") if $scho && not $scored;
  &print_score($self);
}

sub next_player
{
  my $self=shift;
  &print_score($self);
}

sub print_score
{
  my ($self)=@_;
  printf STDERR "\n\n";
  printf STDERR "Runde\t%d\n\n",$self->{round};
  for my $player_idx (0..($self->{player_count}-1))
  {
    printf STDERR "%s\t", ($player_idx == $self->{current_player})?"(".$self->get_player($player_idx)->{name}.")":$self->get_player($player_idx)->{name};
  }
  print STDERR "\n";
  for my $i (1..21)
  {
    for my $player_idx (0..($self->{player_count}-1))
    {
      my $zahl = $i>20?25:$i;
      next if not gueltig($zahl);
      printf STDERR ("%2d %s    ",$zahl, '#' x $self->get_player($player_idx)->{score}->{$zahl}. '-' x (3-$self->get_player($player_idx)->{score}->{$zahl}));
    }
    print STDERR "\n";
  }
  for my $player_idx (0..($self->{player_count}-1))
  {
    printf STDERR ("%3d\t", $self->get_player($player_idx)->{score}->{0});
  }
}
