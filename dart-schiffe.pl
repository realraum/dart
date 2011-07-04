#!/usr/bin/perl
use strict;
use Dart;

our @x= qw/ 20 1 18 4 13 6 10 15 2 17 /;
our @y = qw/ 3 19 7 16 8 11 14 9 12 5 /;
our %x = array_to_hash(@x);
our %y = array_to_hash(@y);
our @schiffe = reverse sort qw/ 3 4 5 /;

$|=1;
my (@player) = @ARGV;


my $dart = new Dart(player_names=>\@player, 
                    callbacks => {
                      shoot=>\&shoot,   
                      before_shoot=>\&print_score,
                      init=>\&init,
                    }
                  );
exit $dart->run();

sub array_to_hash
{
  my @array;
  my %hash;
  for my $key (@array)
  {
    $hash{$key}=1;
  }
  return %hash;
}

### ===============================

sub init
{
  my $self=shift;
  for my $player_idx (0..($self->{player_count}-1))
  {
    $self->get_player($player_idx)->{sel_x}=0;
    $self->get_player($player_idx)->{sel_y}=0;
    for my $x (@x)
    {
      for my $y (@y)
      {
        $self->get_player($player_idx)->{score}->{$x}{$y}=0;
      }
    }
    for my $schiff (@schiffe)
    {
      my $valid=0;
      while(not $valid)
      {
        my $x_start_idx = int(rand(scalar @x));
        my $y_start_idx = int(rand(scalar @y));
        my $direction = int(rand(2));
        my $x_stop_idx = $x_start_idx + $schiff * $direction;
        my $y_stop_idx = $y_start_idx + $schiff * (1-$direction);
        next if ($x_stop_idx > $#x) or ($y_stop_idx > $#y);
        for my $x_idx ($x_start_idx..$x_stop_idx)
        {
          for my $y_idx ($y_start_idx .. $y_stop_idx)
          {
            next if $self->get_player($player_idx)->{score}->{$x[$x_idx]}{$y[$y_idx]};
          }
        }
        for my $x_idx ($x_start_idx..$x_stop_idx)
        {
          for my $y_idx ($y_start_idx .. $y_stop_idx)
          {
            $self->get_player($player_idx)->{score}->{$x[$x_idx]}{$y[$y_idx]}="s";
          }
        }
        $valid=1;
      }
    }
  }
}

sub win_condition
{
  my ($self) = @_;
  for my $x (@x)
  {
    for my $y (@y)
    {
      return if $self->get_current_player()->{score}->{$x}{$y} eq 's';
    }
  }
  return 1;
}

sub shoot
{
  my $self=shift;
  my ($mult,$zahl)=@_;
  my $player=$self->get_current_player();

  if ( (not $x{$zahl}) and (not $y{$zahl}) )
  {
    $self->shout("miss");
    return;
  } elsif ($x{$zahl}) { 
    $player->{sel_x}=$zahl;
  } elsif ($y{$zahl}) { 
    $player->{sel_y}=$zahl;
  }
  $self->shout_last_shoot();
  if ($player->{sel_x} && $player->{sel_y})
  {
    my $x = $player->{sel_x};
    my $y = $player->{sel_y};
    $player->{sel_x}=0;
    $player->{sel_y}=0;
    if ($player->{score}->{$x}{$y} eq 's')
    {
      $self->shout("scored");
      $player->{score}->{$x}{$y} = 'X';
    } elsif (not $player->{score}->{$x}{$y}) {  
      $player->{score}->{$x}{$y} = 'o';
      $self->shout("scho");
    }
  }
  $self->win() if &win_condition($self);
}

sub print_score
{
  my ($self)=@_;
  printf STDERR "Runde\t%d\n\n",$self->{round};
  printf STDERR "Player\t%s\n\n",$self->get_current_player()->{name};
  printf STDERR "x\t%d\n",$self->get_current_player()->{sel_x};
  printf STDERR "y\t%d\n",$self->get_current_player()->{sel_y};

    for my $x (@x)
    {
      for my $y (@y)
      {
        my $field = $self->get_current_player()->{score}->{$x}{$y};
        if ($field eq 'X' or $field eq 'o')
        {
          print STDERR $field;
        } else {
          print STDERR "?";
        }
      }
      print STDERR "\n";
    }
  print STDERR "\n\n";
}
