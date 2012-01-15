#!/usr/bin/perl
use strict;
use Dart;

our $sieb =1; # Spielmodus Zahlensieb


$|=1;
my ($shout_fifo, @player) = @ARGV;

my $dart = new Dart(player_names=>\@player, 
                    shout_fifo=>$shout_fifo,
                    callbacks => {
                      shoot=>\&shoot,   
                      next_player=>\&next_player,
                      before_shoot=>\&print_score,
                      init=>\&init,
                    }
                  );
exit $dart->run();

### ===============================

sub gueltig
{
  my ($zahl,$mult) = @_;
  return $zahl>1;
}

sub init
{
  my $self=shift;
  for my $i (0..21)
  {
    for my $player_idx (0..($self->{player_count}-1))
    {
      my $zahl = $i>20?25:$i;
      next if $zahl > 0 and not gueltig($zahl);
      $self->get_player($player_idx)->{score}->{$zahl}=0;
    }
  }
}

sub win_condition
{
  my ($self) = @_;
  for my $i (keys %{$self->get_current_player()->{score}})
  {
    next if not $i;
    return if $self->get_current_player()->{score}->{$i}<3;
  }
  my $score = $self->get_current_player()->{score}->{0};
  for my $player_idx (0..($self->{player_count}-1))
  {
    next if not $self->get_player($player_idx)->{active};
    return if $score > $self->get_player($player_idx)->{score}->{0};
  }
  return 1;
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
      if ($main::sieb && ($score->{$zahl} == 3))
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
  $self->win() if &win_condition($self);
}

sub next_player
{
  my $self=shift;
}

sub print_score
{
  my ($self)=@_;
  printf "\n\n";
  printf "Runde\t%d\n\n",$self->{round};
  for my $player_idx (0..($self->{player_count}-1))
  {
    printf "%s\t", ($player_idx == $self->{current_player})?"(".$self->get_player($player_idx)->{name}.")":$self->get_player($player_idx)->{name};
  }
  print "\n";
  for my $i (1..21)
  {
    for my $player_idx (0..($self->{player_count}-1))
    {
      my $zahl = $i>20?25:$i;
      next if not gueltig($zahl);
      printf ("%2d %s    ",$zahl, '#' x $self->get_player($player_idx)->{score}->{$zahl}. '-' x (3-$self->get_player($player_idx)->{score}->{$zahl}));
    }
    print "\n";
  }
  for my $player_idx (0..($self->{player_count}-1))
  {
    printf ("%3d\t", $self->get_player($player_idx)->{score}->{0});
  }
}
