#!/usr/bin/perl
use strict;
use Dart;
use Clone;
use Term::ANSIColor;
our @x= qw/ 20 1 18 4 13 6 10 15 2 17 /;
our @y = qw/ 3 19 7 16 8 11 14 9 12 5 /;
our %x = array_to_hash(@x);
our %y = array_to_hash(@y);
our @schiffe = reverse sort qw/ 4 5 6 /;

$|=1;
my ($shout_fifo, @player) = @ARGV;

my $dart = new Dart(player_names=>\@player, 
                    shout_fifo=>$shout_fifo,
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
  for my $x (@main::x)
  {
    for my $y (@main::y)
    {
      $self->{empty_matrix}->{$x}{$y}=0;
    }
  }
  for my $player_idx (0..($self->{player_count}-1))
  {
    $self->get_player($player_idx)->{sel_x}=0;
    $self->get_player($player_idx)->{sel_y}=0;
    $self->get_player($player_idx)->{mult_x}=0;
    $self->get_player($player_idx)->{mult_y}=0;
    delete ($self->get_player($player_idx)->{last_hit});
    $self->get_player($player_idx)->{score}=Clone::clone($self->{empty_matrix});
    $self->get_player($player_idx)->{highlight}{shoot}=Clone::clone($self->{empty_matrix});
    $self->get_player($player_idx)->{highlight}{selected}=Clone::clone($self->{empty_matrix});
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

sub magic_for
{
  my $self=shift;
  my ($x_middle,$mult_x,$y_middle,$mult_y,$sub) = @_;
  #warn  join "\t",($x_middle,$mult_x,$y_middle,$mult_y,$sub);
  my @return;
  die "no function" if not ref $sub;
  my $start_x = $x_middle  ? $main::x{$x_middle}-1 - $mult_x+1 : 0;
  my $stop_x  = $x_middle  ? $main::x{$x_middle}-1 + $mult_x-1 : $#main::x;
  my $start_y = $y_middle  ? $main::y{$y_middle}-1 - $mult_y+1 : 0;
  my $stop_y  = $y_middle  ? $main::y{$y_middle}-1 + $mult_y-1 : $#main::y;
  for my $x_idx ($start_x..$stop_x) 
  {
    my $x = $x_idx> $#main::x ? $main::x[$x_idx-@main::x] : $main::x[$x_idx]; 
    for my $y_idx ($start_y..$stop_y) 
    {
      my $y = $y_idx> $#main::y ? $main::y[$y_idx-@main::y] : $main::y[$y_idx]; 
      push @return, $sub->($self,$x,$y);
    }
  }
  return @return;
}

sub set_highlight_selected
{
  my ($self,$x,$y) = @_;
  $self->get_current_player->{highlight}{selected}{$x}{$y}=1;
}

sub set_shoot
{
  my ($self,$x,$y) = @_;
  my $return;
  my $player=$self->get_current_player();
  $player->{highlight}{shoot}->{$x}{$y} = 1;
  if ($player->{score}->{$x}{$y} eq 's')
  {
    $return = 'scored';
    $player->{score}->{$x}{$y} = 'X';
  } elsif (not $player->{score}->{$x}{$y}) {  
    $player->{score}->{$x}{$y} = 'o';
    $return = 'miss';
  } elsif ($player->{score}->{$x}{$y} eq 'o') {  
    $return = 'scho';
  }
  return $return;
}

sub shoot
{
  my $self=shift;
  my ($mult,$zahl)=@_;
  my $player=$self->get_current_player();
  delete ($player->{last_hit});
  $player->{highlight}{shoot}=Clone::clone($self->{empty_matrix});
  $player->{highlight}{selected}=Clone::clone($self->{empty_matrix});

  if ( (not $main::x{$zahl}) and (not $main::y{$zahl}) )
  {
    $self->shout("miss");
    return;
  } elsif ($main::x{$zahl}) { 
    $player->{sel_x}=$zahl;
    $player->{mult_x}=$mult;
    &magic_for($self,$zahl,$mult,undef,undef,\&set_highlight_selected);
  } elsif ($main::y{$zahl}) { 
    $player->{sel_y}=$zahl;
    $player->{mult_y}=$mult;
    &magic_for($self,undef,undef,$zahl,$mult,\&set_highlight_selected);
  }
  $self->shout_last_shoot();
  if ($player->{sel_x} && $player->{sel_y})
  {
    $player->{highlight}{selected}=Clone::clone($self->{empty_matrix});
    my $x_middle = $player->{sel_x};
    my $y_middle = $player->{sel_y};
    my $mult_x = $player->{mult_x};
    my $mult_y = $player->{mult_y};
    $player->{last_hit}={sel_x=>$x_middle, sel_y=>$y_middle, mult_x=>$mult_x, mult_y=>$mult_y};
    $player->{sel_x}=0;
    $player->{sel_y}=0;
    $player->{mult_x}=0;
    $player->{mult_y}=0;
    my @sound_refs = &magic_for($self,$x_middle,$mult_x,$y_middle,$mult_y,\&set_shoot);
    my %sound;
    map {$sound{$_}++}  @sound_refs;
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


# print with color
sub prcl
{
  my $self = shift;
  my ($color,@what)=@_;
  print color($color) if defined $color;
  print @what;
  print color('reset');
}

sub get_color
{
  my $self = shift;
  my ($x,$y)=@_;
  my $player = $self->get_current_player();
  if ($player->{highlight}{shoot}{$x}{$y})
  {
    return 'bold red';
  } elsif ($player->{highlight}{selected}{$x}{$y}) {
    return 'bold green';
  } elsif ($player->{score}{$x}{$y} eq 'o') {
    return 'blue';
  } elsif ($player->{score}{$x}{$y} eq 'X') {
    return 'bold yellow';
  }
  return 'white';
}

sub prxy
{
  my $self = shift;
  my ($x,$y,@what)=@_;
  &prcl($self,&get_color($self,$x,$y),@what);
}

sub print_score
{
  my ($self)=@_;
  my $player = $self->get_current_player();
  my $sel_x= $player->{sel_x};
  my $sel_y= $player->{sel_y};
  my $mult_x=$player->{mult_x};
  my $mult_y=$player->{mult_y};
  printf "Runde\t%d\n\n",$self->{round};
  printf "Player\t%s\t\tSchuss\t%d\n\n",$player->{name},$self->{current_shoot_count};
  printf "x:  %dx%2d\n",$player->{mult_x},$player->{sel_x};
  printf "y:  %dx%2d\n",$player->{mult_y},$player->{sel_y};

  print "  ";
  for my $y (@main::y)
  {
    printf " %2d",$y;
  }
  print "\n";
  for my $x (@main::x)
  {
    printf "%2d",$x;
    for my $y (@main::y)
    {
      my $field = $self->get_current_player()->{score}->{$x}{$y};
      if ($field eq 'X' or $field eq 'o')
      {
        &prxy($self,$x,$y,"  $field");
      } else {
        &prxy($self,$x,$y,"  .");
      }
    }
    printf "  %d",$x;
    print "\n";
  }
  print "  ";
  for my $y (@main::y)
  {
    printf " %2d",$y;
  }
  print "\n\n";
}
