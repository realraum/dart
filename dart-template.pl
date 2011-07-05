#!/usr/bin/perl
use strict;
use Dart;

$|=1;
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
  # TODO
}

sub win_condition
{
  my ($self) = @_;
  # TODO
  return 0;
}

sub shoot
{
  my $self=shift;
  my ($mult,$zahl)=@_;
  # $self->get_current_player()->{score} = {} if not $self->get_current_player()->{score}; 

  # if (not gueltig($zahl,$mult))
  # {
  #   $self->shout("miss");
  #   return;
  # }

  # $self->shout_last_shoot() if ($scored || $self_scored);
  # $self->shout("scored") if $scored;
  # $self->shout("scho") if $scho && not $scored;
  # $self->win() if &win_condition($self);
}

sub next_player
{
  my $self=shift;

  # TODO
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
  
  # TODO
}
