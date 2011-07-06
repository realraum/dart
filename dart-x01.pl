#!/usr/bin/perl
use strict;
use Dart;

$|=1;
my $maxScore = $0;
$maxScore =~ s/.*\-(\d+).pl$/\1/;
my (@player) = @ARGV;

my $dart = new Dart(player_names=>\@player, 
                    callbacks => {
                      shoot=>\&shoot,   
                      next_player=>\&next_player,
                      before_shoot=>\&print_score,
                      init=>\&init,
                    }
                  );
exit $dart->run();

### ===============================

sub init
{
  my $self=shift;

  for my $player_idx (0..($self->{player_count}-1))
  {
    $self->get_player($player_idx)->{score} = $maxScore;
  }
}

sub win_condition
{
  my ($self) = @_;
  return $self->get_current_player()->{score} == 0;
}

sub shoot
{
  my $self=shift;
  my ($mult,$zahl)=@_;
  
  if ($self->get_current_player()->{score} >= $mult * $zahl)
  {
    $self->get_current_player()->{score} -= $mult * $zahl;
    $self->shout_last_shoot();
    $self->win() if &win_condition($self);
  }
  else
  {
    $self->shout("miss");
    $self->get_current_player()->{score} = $self->get_current_player()->{last_score};
    $self->finish_player_round();
  }
}

sub next_player
{
  my $self=shift;
  $self->get_current_player()->{last_score} = $self->get_current_player()->{score};
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
  for my $player_idx (0..($self->{player_count}-1))
  {
    printf STDERR "%s\t", $self->get_player($player_idx)->{score};
  }
  print STDERR "\n";
}
