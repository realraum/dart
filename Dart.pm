
package Dart;
use strict;
use base 'Exporter';
use Clone;
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
  $self->{current_player}=0;
  my $player_counter=0;
  for my $player_name (@{$params{player_names}}) 
  {
    $player_counter++;
    $self->add_player(&create_player(name=>$player_name,rank=>undef,active=>1));
  }
  $self->{active_player_count}=$player_counter;
  $self->{player_count}=$player_counter;
  $self->{round}=1;
  $self->{max_shoots_per_player}=3;
  $self->{current_shoot_count}=0;
  $self->{callbacks}=$params{callbacks}; 
  $self->callback('init');
  return $self;
}

sub reset_game
{
  my $self=shift;
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
  my ($data_in_fh,$sound_out_fh)=@_;
  my @history;
#  $data_in_fh ||= STDIN;
#  $sound_out_fh ||= STDOUT;
  $self->{sound_out_fh}=$sound_out_fh;

  push @history, Clone::clone($self);
  $self->callback('before_shoot');
  #while ( my $shoot_data = <$data_in_fh>)
  while ( my $shoot_data = <STDIN>)
  {
    #print STDERR $schuss;
    my ($mult,$number) = split /\s+/, $shoot_data;

    if ($mult =~/^\d$/)
    {
      die "Unexpected input" if not $number=~/^\d+$/;
      $self->shoot($mult,$number);
    } elsif ($mult eq 'btn') {
      $self->next_player();
    } elsif ($mult eq 'undo' and $#history) {
      pop @history;
      $self= pop @history;
      $self->callback('undo');
    }
    push @history, Clone::clone($self);
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
    return $self->callback('shoot',$mult,$number);
  } else {
    return 0;
  }
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
  my $fh = $self->{sound_out_fh};
  if ($what eq 25)
  {
    print "bull\n";
  } else {
    print "$what\n";
  }
#print $fh "$what\n";
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
  ($self->{current_player},my $new_round)=get_next_active_player($self->{player},$self->{current_player});
  $self->shout("player");
  $self->shout($self->get_current_player()->{name});
  $self->next_round() if $new_round;
  return $self->callback('next_player');
}

sub get_next_active_player
{
  my ($players_ref,$current_player)=@_;
  my $num_players=@$players_ref;
  my $new_round=0;
  do
  {
    $current_player++;
    if($current_player>=$num_players)
    {
      die "Error no remaining active players" if $new_round;
      $current_player=0;
      $new_round=1;
    }
  }
  while (not $players_ref->[$current_player]{active});
  return ($current_player,$new_round);
}

sub next_round
{
  my $self=shift;
  $self->{round}++;
  return $self->callback('next_round');
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
