
package Dart;
use strict;
use base 'Exporter';
use Clone;
use POSIX;
use Term::Cap;
use FileHandle;

# new Dart(player_names=>[ 'lala', 'popo' ]);
## Player, Rank, Active, 

sub new
{
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my (%params) =@_;
  my $self  = bless {}, $class;
  die "Missing player_names" if not ref $params{player_names} eq 'ARRAY';
  die "Missing player_names" if not @{$params{player_names}};
  $self->{player}=[];
  for my $player_name (@{$params{player_names}}) 
  {
    $self->add_player(&create_player(name=>$player_name,rank=>undef,active=>1));
  }
  $self->{callbacks}=$params{callbacks};

  open($self->{shout_fifo}, '>>', $params{shout_fifo}) or die $!;
  $self->{shout_fifo}->autoflush(1);

  my $termios = new POSIX::Termios;
  $termios->getattr;
  $self->{term} = Term::Cap->Tgetent( { OSPEED => $termios->getospeed } );
  $self->init();
  return $self;
}

sub trace_shoot
{
  my $self=shift;
  my ($property)=@_;
  push @{$self->{trace_shoot}},$property;
}

sub get_color
{
  my $self=shift;
  my ($mul,$zahl)=@_;
  my @zahlen =  qw/20 1 18 4 13 6 10 15 2 17 3 19 7 16 8 11 14 9 12 5 25/;
  my $counter=0;
  $counter++ while($zahl != shift @zahlen and @zahlen);
  $mul=0 if $mul >1;
  my $result = ($counter+$mul )%2;
  return $result;
}

sub init
{
  my $self=shift;
  $self->{round}=0;
  $self->{max_shoots_per_player}=3;
  $self->{current_shoot_count}=0;
  $self->{current_player}=0;
  $self->{player_count}=@{$self->{player}};
  $self->{active_player_count}=$self->{player_count};
  $self->{trace_shoot_data}={};
  $self->callback('init');
}

sub reset_game
{
  my $self=shift;
  my @sort_player = sort { $b->{rank} <=> $a->{rank} } @{$self->{player}};
  $self->{player}=[];
  for my $player (@sort_player)
  {
    $self->add_player(&create_player(name=>$player->{name},rank=>undef,active=>1));
  }
  $self->init();
}

sub callback
{
  my $self=shift;
  my $callbackname = shift;
  if ($self->{callbacks}->{$callbackname})
  {
    return $self->{callbacks}->{$callbackname}->($self,@_);
  } else {
    return 1;
  }
}

sub run
{
  my $self=shift;
  my @history;

  push @history, Clone::clone($self);
  my $STDOUT = new FileHandle '>-';
  $self->{term}->Tputs('cl', 1, $STDOUT);
  $self->callback('before_shoot');
  while ( my $shoot_data = <STDIN>)
  {
    my ($mult,$number) = split /\s+/, $shoot_data;

    if ($mult =~/^\d$/)
    {
      die "Unexpected input" if not $number=~/^\d+$/;
      next if not $self->{current_shoot_count} < $self->{max_shoots_per_player};
      $self->shoot($mult,$number);
    } elsif ($mult eq 'btn') {
      $self->next_player();
    } elsif ($mult eq 'undo' and $#history) {
      pop @history;
      $self= pop @history;
      $self->callback('undo');
    } elsif ($mult eq 'reset') {
      $self->reset_game();
    } elsif ($mult eq 'quit') {
      return;
    } else {
      # shitty input
      next;
    }
    push @history, Clone::clone($self);
    $self->{term}->Tputs('cl', 1, $STDOUT);
    $self->callback('before_shoot');
  }
}

sub shoot
{
  my $self=shift;
  my ($mult,$number)=@_;
  if ($self->{current_shoot_count} < $self->{max_shoots_per_player})
  {
    $self->{current_shoot}={mult=>$mult,number=>$number};
    $self->{current_shoot_count}++;
    my $result = $self->callback('shoot',$mult,$number);
    for my $trace_prop ( @{$self->{trace_shoot}})
    {
      push @{$self->{trace_shoot_data}{$self->{current_player}}},$self->get_current_player()->{$trace_prop};
    }
    return $result;
  } else {
    return 0;
  }
}

sub plot_trace_shoot
{
  my $self=shift;
  my $datastr;
  for my $player_num (keys %{$self->{trace_shoot_data}})
  {
    $datastr.=$self->get_player($player_num)->{name}.':';
    $datastr.= join ',',@{$self->{trace_shoot_data}{$player_num}};
    $datastr.="\n";
  }
  chomp $datastr;
  my $plotter;
  open($plotter,"|./plot.py") or return;
  print $plotter $datastr;
  close $plotter;
}

sub shout_last_shoot
{
  my $self=shift;
  if ($self->{current_shoot}{mult} == 2 && $self->{current_shoot}{number} == 25) {
    $self->shout("bullseye");
    return;
  } elsif ($self->{current_shoot}{mult} == 2 ) {
    $self->shout('double');
  } elsif ($self->{current_shoot}{mult} == 3) {
    $self->shout('triple');
  }

  $self->shout($self->{current_shoot}{number});
}

sub shout
{
  my $self=shift;
  my ($what)=@_;
  my $fh = $self->{shout_fifo};
  if ($what eq 25)
  {
    print $fh "bull\n";
  } else {
    print $fh "$what\n";
  }
}

sub get_current_player
{
  my $self=shift;
  return $self->get_player($self->{current_player});
}

sub get_player
{
  my $self=shift;
  my ($player_idx)=@_;
  die "Illegal Player Index $player_idx" if $player_idx < 0 or $player_idx >= $self->{player_count};
  return $self->{player}[$player_idx];
}

sub next_player
{
  my $self=shift;
  $self->callback('before_next_player');
  $self->{current_shoot_count}=0;
  ($self->{current_player},my $new_round)=$self->get_next_active_player();
  $self->shout("player");
  $self->shout($self->get_current_player()->{name});
  $self->next_round() if $new_round;
  return $self->callback('next_player');
}

sub get_next_active_player
{
  my $self=shift;
  my $players_ref = $self->{player};
  my $current_player = $self->{current_player};
  my $num_players=@$players_ref;
  my $new_round=0;
  do
  {
    $current_player++;
    if($current_player>=$num_players)
    {
      $self->reset_game() if $new_round;
      $current_player=0;
      $new_round=1;
    }
  }
  while (not $self->{player}->[$current_player]{active});
  return ($current_player,$new_round);
}

sub finish_player_round
{
  my $self=shift;
  $self->{current_shoot_count} = $self->{max_shoots_per_player};
}

sub next_round
{
  my $self=shift;
  $self->{round}++;
  return $self->callback('next_round');
}

sub win
{
  my $self=shift;
  $self->shout('win');
  $self->deactivate_current_player($self->{player_count}-$self->{active_player_count}+1);
  if ($self->{active_player_count}==1)
  {
    $self->next_player();
    $self->shout('lose');
    $self->deactivate_current_player($self->{player_count}-$self->{active_player_count}+1);
  }
}

sub lose
{
  my $self=shift;
  $self->shout('lose');
  $self->deactivate_current_player($self->{active_player_count});
  if ($self->{active_player_count}==1)
  {
    $self->next_player();
    $self->shout('win');
    $self->deactivate_current_player($self->{active_player_count});
  }
}

sub deactivate_current_player
{
  my $self=shift;
  my ($rank)=@_;
  $self->{player}[$self->{current_player}]{rank}=$rank;
  $self->{player}[$self->{current_player}]{active}=0;
  $self->{active_player_count}--;
  $self->end_game() if not $self->{active_player_count};
}


sub end_game
{
  my $self=shift;
  $self->shout('end_game');
  return $self->callback('end_game');
}

sub add_player
{ 
  my $self=shift;
  my ($player) = @_;
  push @{$self->{player}}, $player;
}

sub create_player
{
  return {@_};
  #my %player_attributes=@_;
  #my $player = {%player_attributes};
  #return $player;
}

1;
