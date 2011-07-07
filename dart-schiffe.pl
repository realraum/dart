#!/usr/bin/perl
use strict;
use Dart;
use Term::ANSIColor;
our @x= qw/ 20 1 18 4 13 6 10 15 2 17 /;
our @y = qw/ 3 19 7 16 8 11 14 9 12 5 /;
our %x = array_to_hash(@x);
our %y = array_to_hash(@y);
our @schiffe = reverse sort qw/ 4 5 6 /;

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
  my @array=@_;
  my %hash;
  my $i=1;
  for my $key (@array)
  {
    $hash{$key}=$i++;
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
    $self->get_player($player_idx)->{mult_x}=0;
    $self->get_player($player_idx)->{mult_y}=0;
    delete ($self->get_player($player_idx)->{last_hit});
    for my $x (@main::x)
    {
      for my $y (@main::y)
      {
        $self->get_player($player_idx)->{score}->{$x}{$y}=0;
      }
    }
    for my $schiff (@main::schiffe)
    {
      my $valid=0;
      VALIDSHIP: while(not $valid)
      {
        my $x_start_idx = int(rand(scalar @main::x));
        my $y_start_idx = int(rand(scalar @main::y));
        my $direction = int(rand(2));
        my $x_stop_idx = $x_start_idx + ($schiff-1) * $direction;
        my $y_stop_idx = $y_start_idx + ($schiff-1) * (1-$direction);
        #next if ($x_stop_idx > $#main::x) or ($y_stop_idx > $#main::y);
        for my $x_idx ($x_start_idx-1 .. $x_stop_idx+1)
        {
          for my $y_idx ($y_start_idx-1 .. $y_stop_idx+1)
          {
            next VALIDSHIP if $self->get_player($player_idx)->{score}->{$main::x[$x_idx % @main::x]}{$main::y[$y_idx % @main::y]};
          }
        }
        for my $x_idx ($x_start_idx .. $x_stop_idx)
        {
          for my $y_idx ($y_start_idx .. $y_stop_idx)
          {
            $self->get_player($player_idx)->{score}->{$main::x[$x_idx % @main::x]}{$main::y[$y_idx % @main::y]}="s";
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
  for my $x (@main::x)
  {
    for my $y (@main::y)
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
  delete ($player->{last_hit});

  if ( (not $main::x{$zahl}) and (not $main::y{$zahl}) )
  {
    $self->shout("miss");
    return;
  } elsif ($main::x{$zahl}) { 
    $player->{sel_x}=$zahl;
    $player->{mult_x}=$mult;
  } elsif ($main::y{$zahl}) { 
    $player->{sel_y}=$zahl;
    $player->{mult_y}=$mult;
  }
  $self->shout_last_shoot();
  if ($player->{sel_x} && $player->{sel_y})
  {
    my $x_middle = $player->{sel_x};
    my $y_middle = $player->{sel_y};
    my $mult_x = $player->{mult_x};
    my $mult_y = $player->{mult_y};
    $player->{last_hit}={sel_x=>$x_middle, sel_y=>$y_middle, mult_x=>$mult_x, mult_y=>$mult_y};
    $player->{sel_x}=0;
    $player->{sel_y}=0;
    $player->{mult_x}=0;
    $player->{mult_y}=0;

    my $start_x = $main::x{$x_middle}-1 - $mult_x+1;
    my $stop_x = $main::x{$x_middle}-1 + $mult_x-1;
    my $start_y = $main::y{$y_middle}-1 - $mult_y+1;
    my $stop_y = $main::y{$y_middle}-1 + $mult_y-1;
    my %sound;
    for my $x_idx ($start_x..$stop_x) 
    {
      my $x = $x_idx> $#main::x ? $main::x[$x_idx-@main::x] : $main::x[$x_idx]; 
      for my $y_idx ($start_y..$stop_y) 
      {
        my $y = $y_idx> $#main::y ? $main::y[$y_idx-@main::y] : $main::y[$y_idx]; 
        if ($player->{score}->{$x}{$y} eq 's')
        {
          $sound{scored}++;
          $player->{score}->{$x}{$y} = 'X';
        } elsif (not $player->{score}->{$x}{$y}) {  
          $player->{score}->{$x}{$y} = 'o';
          $sound{miss}++;
        } elsif ($player->{score}->{$x}{$y} eq 'o') {  
          $sound{scho}++;
        }
      }
    }

    if ($sound{scored})
    {
      $self->shout("scored");
    } elsif ($sound{miss}) {
      $self->shout("miss");
    } elsif ($sound{scho}) {
      $self->shout("scho");
    }

  }
  $self->win() if &win_condition($self);
}

sub print_score
{
  my ($self)=@_;
  my $player = $self->get_current_player();
  my $sel_x= $player->{sel_x};
  my $sel_y= $player->{sel_y};
  my $mult_x=$player->{mult_x};
  my $mult_y=$player->{mult_y};
  printf STDERR "Runde\t%d\n\n",$self->{round};
  printf STDERR "Player\t%s\t\tSchuss\t%d\n\n",$player->{name},$self->{current_shoot_count};
  printf STDERR "x:  %dx%2d\n",$player->{mult_x},$player->{sel_x};
  printf STDERR "y:  %dx%2d\n",$player->{mult_y},$player->{sel_y};

    print STDERR "  ";
    for my $y (@main::y)
    {
      print STDERR color('bold green') if $sel_y &&  (abs($main::y{$y} - $main::y{$sel_y}) < $mult_y );
      printf STDERR " %2d",$y;
      print STDERR color('reset') if $sel_y &&  (abs($main::y{$y} - $main::y{$sel_y}) < $mult_y );

    }
    print STDERR "\n";
    for my $x (@main::x)
    {
      print STDERR color 'bold green' if $sel_x &&  (abs($main::x{$x} - $main::x{$sel_x}) < $mult_x );
      printf STDERR "%2d",$x;
      for my $y (@main::y)
      {
        print STDERR color('bold green') if $sel_y &&  (abs($main::y{$y} - $main::y{$sel_y}) < $mult_y );
        my $field = $self->get_current_player()->{score}->{$x}{$y};
        if ($field eq 'X' or $field eq 'o')
        {
          print STDERR "  $field";
        } else {
          print STDERR "  .";
        }
        print STDERR color('reset') if $sel_y &&  (abs($main::y{$y} - $main::y{$sel_y}) < $mult_y );
      }
      printf STDERR "  %d",$x;
      print STDERR color 'reset';
      print STDERR "\n";
    }
    print STDERR "  ";
    for my $y (@main::y)
    {
      print STDERR color('bold green') if $sel_y &&  (abs($main::y{$y} - $main::y{$sel_y}) < $mult_y );
      printf STDERR " %2d",$y;
      print STDERR color('reset') if $sel_y &&  (abs($main::y{$y} - $main::y{$sel_y}) < $mult_y );

    }
  print STDERR "\n\n";
}
