#
# $Id: Font.pm,v 1.5 2003/11/08 16:42:01 rdw Exp $
# 

package PerlWM::X::Font;

############################################################################

use strict;
use warnings;

############################################################################

sub font_init {
  
  my($self) = @_;

  return { create => \&font_create, info => \&font_info };
}

############################################################################

sub font_create {

  my($self, $spec) = @_;

  # TODO: come up with a better (generic) error handling strategy
  my($id, %info) = $self->new_rsrc();
  local $self->{die_on_error} = 1;
  foreach ($spec, 'fixed') {
    eval { 
      $self->OpenFont($id, $_); 
      %info = $self->QueryFont($id);
    };
    if ($@ && ($@ =~ /^OpenFont/)) {
      eval { $self->handle_input(); };
      die unless $@ && $@ =~ /^QueryFont/;
    }
    last unless $@;
  }
  return ($id, \%info);
}

############################################################################

sub font_info {
  
  my($self, $id) = @_;
  my %info = $self->QueryFont($id);
  return \%info;
}

############################################################################

sub font_text_width {

  my($self, $font, $string) = @_;
  my $info = $self->font_info($font);
  # TODO: handle multibyte fonts properly
  die "can't deal with a font like that yet\n"
    unless ($info->{min_byte1} == 0) && ($info->{max_byte1} == 0);
  # this might be a bad idea!
  $info->{size_cache} ||= { };
  my $cache = $info->{size_cache};
  # this might be even worse!
  my @words = split / /, $string;
  my $width = $info->{char_infos}->[ord(' ') - $info->{min_char_or_byte2}]->[2];
  $width *= scalar @words;
  foreach (@words) {
    my $word_width = $cache->{$_};
    unless (defined($word_width)) {
      foreach (split //, $_) {
	$word_width += $info->{char_infos}->[ord($_) - $info->{min_char_or_byte2}]->[2];
      }
      $cache->{$_} = $word_width;
    }
    $width += $word_width;
  }
  return $width;
}

############################################################################

1;

