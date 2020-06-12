#
# $Id: Label.pm,v 1.6 2004/05/23 14:22:21 rdw Exp $
# 

package PerlWM::Widget::Label;

############################################################################

use strict;
use warnings;

use base qw(PerlWM::Widget);

use PerlWM::Widget::Tie;

############################################################################

sub new {

  my($proto, %arg) = @_;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $self = $class->SUPER::new(%arg);

  $self->{padding} ||= 0;
  $self->{value} ||= '';
  $self->{class} = $arg{class} ? "widget/$arg{class}" : "widget";

  $self->{foreground_spec} = $arg{foreground} || $self->{class}.'/foreground';
  $self->{background_spec} = $arg{background} || $self->{class}.'/background';
  $self->{font_spec} = $arg{font} || $self->{class}.'/font';

  tie($self->{value}, 'PerlWM::Widget::Tie::Scalar', 
      $self->{value}, \&onValueChange, $self);

  $self->{gc} = $self->{x}->gc_get($self->{class}, 
				   { foreground => $self->{foreground_spec},
				     background => $self->{background_spec},
				     font => $self->{font_spec} });
  $self->{ascent} = $self->{x}->font_info($self->{font_spec})->{font_ascent};
  $self->{descent} = $self->{x}->font_info($self->{font_spec})->{font_descent};
  $self->{font} = $self->{x}->font_get($self->{font_spec});

  return $self;
}

############################################################################

sub onValueChange {

  my($self, $value) = @_;
  if ($self->{frozen}) {
    $self->{frozen}++;
  }
  else {
    $self->resize() if $self->{resize};
    $self->ClearArea(0, 0, 0, 0);
    $self->draw($value);
  }
}

############################################################################

sub draw {

  my($self, $value) = @_;
  $self->PolyText8($self->{gc},
		   $self->{padding}, $self->{padding} + $self->{ascent},
		   $self->{font}, [0, $value]);
}

############################################################################

sub onExpose { 

  my($self, $event) = @_;
  $self->draw($self->{value});
}

############################################################################

sub create {

  my($self, %args) = @_;
  if ($args{width} eq 'auto') {
    $args{width} = $self->{x}->font_text_width($self->{font_spec}, $self->{value});
    $args{width} += (2 * $self->{padding}) if $self->{padding};
  }
  if ($args{height} eq 'auto') {
    $args{height} = $self->{ascent} + $self->{descent};
    $args{height} += (2 * $self->{padding}) if $self->{padding};
  }
  $args{background_pixel} ||= $self->{x}->color_get($self->{background_spec});
  return $self->SUPER::create(%args);
}

############################################################################

sub resize {

  my($self) = @_;
  my $width = $self->{x}->font_text_width($self->{font_spec}, $self->{value});
  $self->ConfigureWindow(width => $width + ($self->{padding} * 2));
}

############################################################################

sub EVENT { (__PACKAGE__->SUPER::EVENT,
	     'Expose' => 'onExpose') }

############################################################################


1;
