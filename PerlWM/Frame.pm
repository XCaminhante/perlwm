#
# $Id: Frame.pm,v 1.25 2004/05/23 14:26:13 rdw Exp $
#

package PerlWM::Frame;

############################################################################

use strict;
use warnings;
use base qw(PerlWM::X::Window);

use PerlWM::Action;
use PerlWM::Widget::Label;

############################################################################

BEGIN {
  my $frame = PerlWM::Config->new('default/frame');
  $frame->set('blur' => '#ffffff',
	      'focus' => '#ff0000',
	      'border_width' => 2,
	      'title/background' => '#000000',
	      'title/foreground' => '#ffffff',
	      'title/font' => 
	      '-b&h-lucida-medium-r-normal-*-*-100-*-*-p-*-iso8859-1');
};

############################################################################

sub new {

  my($proto, %args) = @_;
  my $class = ref($proto) || $proto || __PACKAGE__;
  my $self = $class->SUPER::new(%args);

  $self->{client} = PerlWM::X::Window->new(x => $self->{x},
					   id => $self->{client_id});
  # set the do not propogate mask for all input events
  my $input = $self->{x}->pack_event_mask(qw(KeyPress KeyRelease
					     ButtonPress ButtonRelease),
					  map "Button${_}Motion", (1..5));
  $self->{client}->ChangeWindowAttributes(do_not_propogate_mask => $input);

  $self->{client}->event_overlay_add($self);
  
  my $previous_state = ($self->{client}->{prop}->{WM_STATE} &&
			$self->{client}->{prop}->{WM_STATE}->{state});

  $self->{client}->{prop}->{WM_STATE} = { state => ($previous_state || 'Normal') };

  $self->{x}->ChangeSaveSet('Insert', $self->{client_id});

  my %geom = $self->{client}->GetGeometry();

  my($mask, @grab) = $self->event_mask();

  $mask |= $self->{x}->pack_event_mask('SubstructureNotify',
				       'SubstructureRedirect');

  $self->{border_width} = PerlWM::Config->get('frame/border_width');

  $geom{x} ||= $self->{border_width};
  $geom{y} ||= ($self->{border_width} * 2) + 18;

  $self->create(x => $geom{x} - $self->{border_width},
		y => $geom{y} - (($self->{border_width} * 2) + 18),
		width => $geom{width} + ($self->{border_width} * 2),
		height => $geom{height} + ($self->{border_width} * 3) + 18,
		background_pixel => $self->{x}->color_get('frame/blur'),
		event_mask => $mask);

  # grab things (but not things without modifiers)
  $self->event_grab(grep $_->{mods}, @grab);

  $self->{label} = PerlWM::Widget::Label->new
    (x => $self->{x},
     padding => 2,
     value => $self->{client}->{prop}->{WM_NAME},
     foreground => 'frame/title/foreground',
     background => 'frame/title/background',
     font => 'frame/title/font');
  $self->{name} = $self->{client}->{prop}->{WM_NAME};

  $self->{label}->create(parent => $self,
			 x => $self->{border_width}, 
			 y => $self->{border_width},
			 width => $geom{width}, 
			 height => 18);
  $self->{label}->MapWindow();

  $self->{client}->ConfigureWindow(border_width => 0);
  $self->{client}->ReparentWindow($self->{id}, 
				  $self->{border_width}, 
				  ($self->{border_width} * 2) + 18);

  $self->{client}->MapWindow() if $args{map_request};

  push @{$self->{perlwm}->{frames}}, $self;

  if ($previous_state && ($previous_state eq 'Iconic')) {
    $self->iconify();
  }
  else {
    $self->MapWindow();
  }

  return $self;
}

############################################################################

sub geom {

  my($self, %geom) = @_;
  %geom = $self->GetGeometry() unless %geom || $self->{geom};
  $self->{geom}->{$_} = $geom{$_} for keys %geom;
  $self->{geom}->{position} = [@{$self->{geom}}{qw(x y)}];
  $self->{geom}->{size} = [@{$self->{geom}}{qw(width height)}];
  return $self->{geom};
}

############################################################################

sub position {

  my($self) = @_;
  my $position = $self->geom()->{position};
  $position->[0] += $self->{border_width};
  $position->[1] += ($self->{border_width} * 2) + 18;
  return $position;
}

############################################################################

sub size {

  my($self) = @_;
  my $size = $self->geom()->{size};
  $size->[0] -= ($self->{border_width} * 2);
  $size->[1] -= ($self->{border_width} * 3) + 18;
  return $size;
}

############################################################################

sub configure {

  my($self, %arg) = @_;

  my(%frame, %client);
  my($size, $position) = @arg{qw(size position)};
  
  if ($size) {
    my $orig = [@{$size}];
    $size = $self->check_size_hints($size);
    if ((my $anchor = $arg{anchor}) && 
	(($size->[0] != $orig->[0]) ||
	 ($size->[1] != $orig->[1]))) {
      $position ||= $self->position();
      $position = [@{$position}];
      $position->[$_] += (($size->[$_] - $orig->[$_]) * 
			  (($anchor->[$_] < 0) ? -1 : 0)) for (0, 1);
    }
    $frame{width} = $size->[0] + ($self->{border_width} * 2);
    $frame{height} = $size->[1] + ($self->{border_width} * 3) + 18;
    $client{width} = $size->[0];
    $client{height} = $size->[1];
  }
  if ($position) {
    $frame{x} = $position->[0] - $self->{border_width};
    $frame{y} = $position->[1] - (($self->{border_width} * 2) + 18);
    $client{x} = $position->[0];
    $client{y} = $position->[1];
  }
  if (%arg) {
    $self->ConfigureWindow(%frame);
    $self->geom(%frame);
    $self->{label}->ConfigureWindow(width => ($frame{width} - 
					      ($self->{border_width} * 2)))
      if $frame{width};
    $size ||= $self->size();
    my %event = ( name => 'ConfigureNotify',
		  window => $self->{client}->{id},
		  event => $self->{client}->{id},
		  x => $client{x},
		  y => $client{y},
		  width => $size->[0],
		  height => $size->[1],
		  border_width => 0,
		  above_sibling => $self->{id},
		  override_redirect => 0 );
    $self->{client}->SendEvent(0, 
			       $self->{x}->pack_event_mask('StructureNotify'), 
			       $self->{x}->pack_event(%event));
    $self->{client}->ConfigureWindow(width => $size->[0],
				     height => $size->[1]) if $arg{size};
  }
}

############################################################################

sub configure_request {

  my($self, $event) = @_;
  my $xe = $event->{xevent};
  $self->{x}->ConfigureWindow($xe->{window},
			      map { exists $xe->{$_}?($_=>$xe->{$_}):()
				  } qw(x y width height 
				       border_width sibling stack_mode));
  if (defined($xe->{width}) && defined($xe->{height})) {
    $self->ConfigureWindow
      (width => $xe->{width} + ($self->{border_width} * 2),
       height => $xe->{height} + ($self->{border_width} * 3) + 18);
  }
}

############################################################################

sub focus {

  my($self, $event) = @_;
  return unless my $client = $self->{client};
  return if $self->{perlwm}->{focus} == $self;

  $client->SetInputFocus('PointerRoot', 'CurrentTime');
  if ($self->wm_protocol_check('WM_TAKE_FOCUS')) {
    # force a sync
    $self->{x}->GetInputFocus();
    my %event = ( name => 'ClientMessage',
		  window => $self->{client}->{id},
		  type => $self->{x}->atom('WM_PROTOCOLS'),
		  format => 32,
		  data => pack('L5', 
			       $self->{x}->atom('WM_TAKE_FOCUS'), 
			       $self->{x}->{timestamp}) );
    $client->SendEvent(0, $self->{x}->pack_event_mask('ClientMessage'),
		       $self->{x}->pack_event(%event));
  }
  $self->{perlwm}->{focus} = $self;
  $self->{perlwm}->{prop}->{PERLWM_FOCUS} = $self->{id};
}

############################################################################

sub enter {

  my($self, $event) = @_;
  if ($event) {
    return if $event->{detail} eq 'Inferior';
    return if $event->{mode} eq 'Grab';
  }
  $self->focus();
  $self->ChangeWindowAttributes(background_pixel => $self->{x}->color_get('frame/focus'));
  $self->ClearArea();
  $self->timer_set(10000, 'Raise');
}

############################################################################

sub leave {

  my($self, $event) = @_;
  return unless my $client = $self->{client};
  if ($event) {
    return if $event->{detail} eq 'Inferior';
    return unless $event->{mode} eq 'Normal';
  }
  return unless $self->{perlwm}->{focus} == $self;

  $self->{perlwm}->SetInputFocus('PointerRoot', $self->{x}->{timestamp});
  $self->{perlwm}->{focus} = $self->{perlwm};
  $self->ChangeWindowAttributes(background_pixel => $self->{x}->color_get('frame/blur'));
  $self->ClearArea();
  $self->timer_set(0, 'Raise');
}

############################################################################

sub auto_raise {

  my($self, $event) = @_;
  return unless $self->{perlwm}->{focus} == $self;
  $self->ConfigureWindow(stack_mode => 'Above');
}

############################################################################

sub destroy_notify {

  my($self, $event) = @_;
  $self->{client}->detach(destroyed => 1);
  $self->{client} = undef;
  $self->destroy();
  $self->{perlwm}->{frames} = [ grep $_ != $self, @{$self->{perlwm}->{frames}} ];
}

############################################################################

sub map_notify {

  my($self, $event) = @_;
  return if $self->{client}->{prop}->{WM_STATE}->{state} eq 'Iconic';
  $self->MapWindow();
}

############################################################################

sub unmap_notify {

  my($self, $event) = @_;
  return if $self->{client}->{iconified};
  $self->UnmapWindow();
}

############################################################################

sub iconify {

  my($self) = @_;
  $self->{icon} ||= PerlWM::Icon->new(x => $self->{x}, frame => $self);
  $self->{icon}->MapWindow();
  $self->{client}->{prop}->{WM_STATE} = { state => 'Iconic',
					  icon => $self->{icon}->{id} };
  $self->UnmapWindow();
}

############################################################################

sub deiconify {

  my($self) = @_;
  $self->MapWindow();
  $self->{icon}->UnmapWindow() if $self->{icon};
  $self->{client}->{prop}->{WM_STATE} = { state => 'Normal' };
}

############################################################################

sub delete_or_destroy {

  my($self) = @_;
  return unless my $client = $self->{client};
  
  if ($self->wm_protocol_check('WM_DELETE_WINDOW')) {
    my %event = ( name => 'ClientMessage',
		  window => $self->{client}->{id},
		  type => $self->{x}->atom('WM_PROTOCOLS'),
		  format => 32,
		  data => pack('L5', $self->{x}->atom('WM_DELETE_WINDOW')) );
    $client->SendEvent(0, $self->{x}->pack_event_mask('ClientMessage'),
		       $self->{x}->pack_event(%event));
  }
  else {
    $client->DestroyWindow();
  }
}

############################################################################

sub check_size_hints {

  my($self, $size) = @_;

  if (my $hints = $self->{client}->{prop}->{WM_NORMAL_HINTS}) {
    $size = [@{$size}];
    foreach (0,1) {
      if (my $min = $hints->{PMinSize}) {
	$size->[$_] = $min->[$_] if $size->[$_] < $min->[$_];
      }
      if (my $inc = $hints->{PResizeInc}) {
	my $base = $hints->{PBaseSize};
	$size->[$_] -= $base->[$_] if $base;
	$size->[$_] = $inc->[$_] * (int($size->[$_] / $inc->[$_]));
	$size->[$_] += $base->[$_] if $base;
      }
    }
  }
  return $size;
}

############################################################################

sub prop_wm_name {

  my($self, $event) = @_;
  return unless my $client = $self->{client};
  my $name = $client->{prop}->{WM_NAME};
  if ($self->{icon} && (!$client->{prop}->{WM_ICON_NAME})) {
    $self->{icon}->name($name);
  }
  $self->{label}->{value} = $name;
  $self->{name} = $name;
}

############################################################################

sub find_frame {

  my($self, $offset) = @_;

  my $frames = $self->{perlwm}->{frames};
  my $nframes = scalar @{$frames};
  for (my $index = 0; $index < $nframes; $index++) {
    if ($frames->[$index] == $self) {
      $index += $offset;
      $index += $nframes if $index < 0;
      $index -= $nframes if $index >= $nframes;
      return $frames->[$index];
    }
  }
  return $self;
}

############################################################################

sub warp_to {

  my($self, $position) = @_;
  my $size = $self->size();
  for (0, 1) { 
    $position->[$_] += $size->[$_] if $position->[$_] < 0;
  }
  $self->{x}->WarpPointer('None', $self->{id}, 0, 0, 0, 0, @{$position});
  $self->focus();
}

############################################################################

sub wm_protocol_check {

  my($self, $protocol) = @_;
  return 0 unless my $client = $self->{client};
  return 0 unless my $prop = $client->{prop}->{WM_PROTOCOLS};
  $prop = [$prop] unless ref $prop;
  foreach (@{$prop}) {
    return 1 if $_ eq $protocol;
  }
  return 0;
}

############################################################################

action_register('keyboard_move', 'PerlWM::Action::Move');
action_register('keyboard_resize', 'PerlWM::Action::Resize');
action_register('keyboard_search', 'PerlWM::Action::Search');

sub EVENT { ( __PACKAGE__->SUPER::EVENT,

	      # TODO: load these bindings via some config stuff
	      'Drag(Button1)' => action('move_opaque'),
	      'Drag(Mod1 Button1)' => action('move_opaque'),

	      'Click(Button1)' => action('raise_window'),
	      'Click(Mod1 Button1)' => action('raise_window'),

	      'Click(Button3)' => action('iconify_window'),
	      'Click(Mod1 Button3)' => action('iconify_window'),

	      'Drag(Button2)' => action('resize_opaque'),
	      'Drag(Mod1 Button2)' => action('resize_opaque'),

	      'Key(Mod4 Enter)' => action('iconify_window'),

	      'Key(Mod4 m)' => action('keyboard_move'),
	      'Key(Mod4 r)' => action('keyboard_resize'),

	      'Key(Mod4 Up)' => action('raise_window'),
	      'Key(Mod4 Down)' => action('lower_window'),

	      'Key(Mod4 Left)' => action('focus_previous'),
	      'Key(Mod4 Right)' => action('focus_next'),

	      'Key(Mod4 s)' => action('keyboard_search'),

	      'Key(Mod4 w)' => action('close_window'),

	      # TODO: config for focus policy
	      'Enter' => \&enter,
	      'Leave' => \&leave,
	      'Timer(Raise)' => \&auto_raise,

	      'ConfigureRequest' => \&configure_request,
	      'DestroyNotify' => \&destroy_notify,
	      'MapNotify' => \&map_notify,
	      'UnmapNotify' => \&unmap_notify ) }

sub OVERLAY { ( 'Property(WM_NAME)' => \&prop_wm_name ) }

############################################################################

1;
