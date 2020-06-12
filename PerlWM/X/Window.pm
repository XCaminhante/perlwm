#
# $Id: Window.pm,v 1.10 2004/02/16 10:52:30 rdw Exp $
#

package PerlWM::X::Window;

############################################################################

use strict;
use warnings;

use PerlWM::X::Property;

############################################################################

sub new {

  my($proto, %args) = @_;

  my $class = ref($proto) || $proto || __PACKAGE__;
  my $self = { %args };
  bless $self, $class;

  die "no x" unless $self->{x};
  die "invalid x" unless $self->{x}->isa('PerlWM::X');

  $self->attach() if $self->{id};

  return $self;
}

############################################################################

sub attach {

  my($self) = @_;

  $self->{x}->window_attach($self);
  unless ($self->{no_props}) {
    $self->{prop_obj} = tie my %prop, 'PerlWM::X::Property', $self;
    $self->{prop} = \%prop;
  }
}

############################################################################

sub detach {

  my($self, %args) = @_;

  $self->{x}->window_detach($self, %args);
  untie $self->{prop};
  delete $self->{prop_obj};
}

############################################################################

sub create {

  my($self, %args) = @_;

  # allow naming of args, and supply defaults
  my @args = (delete $args{parent} || $self->{x}->{root},
	      delete $args{class} || 'InputOutput',
	      delete $args{depth} || 'CopyFromParent',
	      delete $args{visual} || 'CopyFromParent',
	      delete $args{x} || 0 ,
	      delete $args{y} || 0 ,
	      delete $args{width} || 100 ,
	      delete $args{height} || 100,
	      delete $args{border_width} || 0);

  $args[0] = $args[0]->{id} if ref $args[0];

  $args{bit_gravity} ||= 'Static'; 

  $args{event_mask} ||= $self->event_mask();

  $self->{id} = $self->{x}->new_rsrc();
  $self->CreateWindow(@args, %args);
  $self->{event_mask} = $args{event_mask};
  $self->attach();
}

############################################################################

sub destroy {

  my($self) = @_;
  $self->detach();
  $self->DestroyWindow();
}

############################################################################

sub event_mask {

  my($self, $mask) = @_;
  return $self->{x}->event_window_mask($self, $mask);
}

############################################################################

sub event_grab {

  my($self, @grab) = @_;
  return $self->{x}->event_window_grab($self, @grab);
}

############################################################################

sub event_overlay_add {

  my($self, $overlay) = @_;
  return $self->{x}->event_overlay_add($self, $overlay);
}

############################################################################

sub event_overlay_remove {

  my($self, $overlay) = @_;
  return $self->{x}->event_overlay_remove($self, $overlay);
}

############################################################################

sub timer_set {

  my($self, $time, $tag) = @_;
  $self->{x}->event_timer($time, $self->{id}, $tag);
}

############################################################################

sub position {

  my($self) = @_;
  my %geom = $self->GetGeometry();
  return [$geom{x}, $geom{y}];
}

############################################################################

sub EVENT {

  return ();
}

############################################################################

sub AUTOLOAD {

  my($self, @args) = @_;
  no strict 'vars';
  my $method = $AUTOLOAD;
  my $class = ref $self;
  $method =~ s/\Q$class\E:://;
  return if $method =~ /^DESTROY/;
  die "uh-oh ($self->$method())\n" unless ref $self;
  die "no id ($method)\n" unless $self->{id};
  $self->{x}->$method($self->{id}, @args);
}

############################################################################

1;
