#
# $Id: Key.pm,v 1.2 2004/02/16 10:52:14 rdw Exp $
#

package PerlWM::X::Key;

############################################################################

use strict;
use warnings;

############################################################################

my %KEYSYM =
  ( Backspace => 0xff08, Tab => 0xff09, Enter => 0xff0d,
    Escape => 0xff1b, Home => 0xff50, Left => 0xff51,
    Up => 0xff52, Right => 0xff53, Down => 0xff54,
    PageUp => 0xff55, PageDown => 0xff56, End => 0xff57 );

my %RKEYSYM = reverse %KEYSYM;

############################################################################

sub key_init {

  my($self) = @_;
  unless ($self->{key}) {
    my $key = $self->{key} = { };
    my($min, $max) = @{$self}{qw(min_keycode max_keycode)};
    my(@keys) = $self->GetKeyboardMapping($min, ($max - $min) + 1);
    my $keycode = $min;
    foreach my $ks (@keys) {
      foreach (@{$ks}) {
	next unless $_;
	push @{$key->{code}->{$keycode}}, $_;
	push @{$key->{sym}->{$_}}, $keycode;
      }
      $keycode++;
    }
  }
  return $self->{key};
}

############################################################################

sub key_code_to_sym {

  my($self, $code, $offset) = @_;
  my $key = $self->{key} || $self->key_init();
  return $key->{code}->{$code}->[$offset || 0];
}

############################################################################

sub key_sym_to_code {

  my($self, $sym) = @_;
  my $key = $self->{key} || $self->key_init();
  return $key->{sym}->{$sym}->[0];
}

############################################################################

sub key_string_to_sym {

  my($self, $string) = @_;
  if ($string =~ /^[ -~]$/) {
    return ord($string);
  }
  else {
    return $KEYSYM{$string} || 0;
  }
}

############################################################################

sub key_sym_to_string {

  my($self, $sym) = @_;
  if (($sym >= 32) && ($sym <= 126)) {
    return chr($sym);
  }
  else {
    return $RKEYSYM{$sym} || sprintf "%04x", $sym;
  }
}

############################################################################

1;

