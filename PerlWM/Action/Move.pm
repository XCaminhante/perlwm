#
# $Id: Move.pm,v 1.4 2003/12/22 22:16:02 rdw Exp $
#

package PerlWM::Action::Move;

############################################################################

use strict;
use warnings;
use base qw(PerlWM::Action);

############################################################################

my %DIR = ( Up => [0, -1], Down => [0, 1],
	    Left => [-1, 0], Right => [1, 0] );

my %SPEED = ( 0 => 5, # normal
	      1 => 1, # shift
	      4 => 10, # control
	      8 => 25, # mod1
	      12 => 50, # control + mod1
	    );

############################################################################

sub start {

  my($target, $event) = @_;
  my $self = __PACKAGE__->SUPER::new(target => $target,
				     event => $event,
				     grab => 'keyboard');

  $target->ConfigureWindow(stack_mode => 'Above');
  $self->{orig_position} = $target->position();
  $self->{position} = [@{$self->{orig_position}}];
  return $self;
}

############################################################################

sub move_by {

  my($self, $delta) = @_;
  $self->{position}->[$_] += $delta->[$_] for (0,1);
  $self->{x}->WarpPointer('None', 'None', 0, 0, 0, 0, @{$delta});
  $self->{target}->configure(position => $self->{position});
}

############################################################################

sub cancel {

  my($self) = @_;
  $self->{target}->configure(position => $self->{orig_position});
  $self->SUPER::cancel();
}

############################################################################

sub delta_key {

  my($self, $event) = @_;
  return unless my $delta = $DIR{$event->{string}};
  return unless my $factor = $SPEED{$event->{state}};
  $self->move_by([$delta->[0] * $factor, $delta->[1] * $factor]);
}

############################################################################

sub OVERLAY {

  my %delta_key;
  foreach my $key (keys %DIR) {
    foreach my $mod ("", "Shift ", "Control ", "Mod1 ", "Control Mod1 ") {
      $delta_key{"Key($mod$key)"} = \&delta_key;
    }
  }

  ( __PACKAGE__->SUPER::OVERLAY,

    %delta_key,

    'Key(Enter)' => 'finish') }

############################################################################

1;
