#
# $Id: Icon.pm,v 1.7 2004/05/23 14:25:25 rdw Exp $
#

package PerlWM::Icon;

############################################################################

use strict;
use warnings;
use base qw(PerlWM::X::Window);

use PerlWM::Action;
use PerlWM::Widget::Label;

############################################################################

BEGIN {
  my $config = PerlWM::Config->new('default/icon');
  $config->set('background' => '#000000',
	       'foreground' => '#ffffff',
	       'border_color' => '#ffffff',
	       'border_width' => 2,
	       'font' => '-b&h-lucida-medium-r-normal-*-*-100-*-*-p-*-iso8859-1');
};

############################################################################

sub new {

  my($proto, %args) = @_;
  my $class = ref($proto) || $proto || __PACKAGE__;
  my $self = $class->SUPER::new(%args);

  my $name = ($self->{frame}->{client}->{prop}->{WM_ICON_NAME} ||
	      $self->{frame}->{client}->{prop}->{WM_NAME});

  my %geom = $self->{frame}->GetGeometry();

  $self->{border_width} = PerlWM::Config->get('icon/border_width');

  $self->create(x => $geom{x},
		y => $geom{y},
		width => ($self->{border_width} * 2) + 50,
		height => ($self->{border_width} * 2) + 18,
		background_pixel => $self->{x}->color_get('icon/border_color'));

  $self->{label} = PerlWM::Widget::Label->new
    (x => $self->{x},
     padding => 2,
     resize => 'auto',
     foreground => 'icon/foreground',
     background => 'icon/background',
     font => 'icon/font',
     value => $name);

  $self->{label}->create(parent => $self,
			 x => $self->{border_width}, 
			 y => $self->{border_width},
			 width => 'auto', 
			 height => 'auto');
  $self->{label}->MapWindow();

  $self->{frame}->{client}->event_overlay_add($self);

  %geom = $self->{label}->GetGeometry();
  $self->ConfigureWindow(width => $geom{width} + ($self->{border_width} * 2), 
			 height => $geom{height} + ($self->{border_width} * 2));

  return $self;
}

############################################################################

sub name {

  my($self, $name) = @_;
  $self->{label}->{value} = $name;
  $self->{label}->resize();
  my %geom = $self->{label}->GetGeometry();
  $self->ConfigureWindow(width => $geom{width} + ($self->{border_width} * 2), 
			 height => $geom{height} + ($self->{border_width} * 2));
}

############################################################################

sub prop_wm_icon_name {

  my($self, $event) = @_;
  $self->name($self->{frame}->{client}->{prop}->{WM_ICON_NAME});
}

############################################################################

sub EVENT { ('Drag(Button1)' => action('move_icon_opaque'),
	     'Drag(Mod1 Button1)' => action('move_icon_opaque'),
	     'Click(Button1)', action('deiconify_window'),
	     'Click(Double Button1)', action('deiconify_window') ) }

sub OVERLAY { ( 'Property(WM_ICON_NAME)' => \&prop_wm_icon_name ) }

############################################################################

1;
