#!/usr/bin/perl
use strict;
use Dart;

$|=1;
my $maxScore = $0;
$maxScore =~ s/.*\-(\d+).pl$/\1/;
my ($shout_fifo, @player) = @ARGV;

my $dart = new Dart(player_names=>\@player, 
                    shout_fifo=>$shout_fifo,
                    callbacks => {
                      shoot=>\&shoot,   
                      next_player=>\&next_player,
                      before_shoot=>\&print_score,
                      init=>\&init,
                      end_game=>\&Dart::plot_trace_shoot,
                    }
                  );
$dart->trace_shoot('score');
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
  my $color = $self->get_color($mult,$zahl)?1:-1; 
  if ($color <0)
  {
    $self->shout("plus");
  }else{
    $self->shout("minus");
  }
  $self->get_current_player()->{score} -= $color *$mult * $zahl;
  $self->shout_last_shoot();
  $self->win() if &win_condition($self);
}

sub next_player
{
  my $self=shift;
  $self->get_current_player()->{last_score} = $self->get_current_player()->{score};
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
  for my $player_idx (0..($self->{player_count}-1))
  {
    printf "%s\t", $self->get_player($player_idx)->{score};
  }
  print "\n";
}
