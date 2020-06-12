#
# $Id: Color.pm,v 1.3 2003/06/08 13:43:35 rdw Exp $
# 

package PerlWM::X::Color;

############################################################################

use strict;
use warnings;

############################################################################

sub color_init {
  
  my($self) = @_;

  my $s = $self->{root_depth};
  my $v = $self->{visuals}->{$self->{root_visual}};
  my($rm, $gm, $bm) = @{$v}{qw(red_mask green_mask blue_mask)};
  my($rs, $gs, $bs) = map { my($m, $r) = ($_, -16);
			    while ($m) {
			      $r++;
			      $m >>= 1;
			    }
			    $r ? (($r < 0) ? " >> ".-$r : " << $r") : "";
			  } $rm, $gm, $bm;
  $self->{color_helper} = eval qq{sub {
				    my(\$r, \$g, \$b) = \@_;
				    return (((\$r$rs) & $rm) | 
					    ((\$g$gs) & $gm) | 
					    ((\$b$bs) & $bm)); }} or die $@;

  $self->color_add('default', 'black', $self->{black_pixel}, [0, 0, 0]);

  return { create => \&color_create };
}

############################################################################

sub color_create {

  my($self, $spec) = @_;

  $spec =~ tr/A-Z \t/a-z/d;

  # TODO: non direct/true color support

  my($pixel, @rgb); 
  if ($spec =~ /^\#([0-9a-f]+)$/i) {
    my $t = length($1) / 3;
    my $p = "0" x (4 - $t);
    (@rgb) = map hex(substr($1, $t * $_, $t).$p), (0..2);
  }
  elsif ($spec =~ /^rgb(?:i?):([0-9a-f]+)\/([0-9a-f]+)\/([0-9a-f]+)/i) {
    (@rgb) = map hex($_.("0"x(4 - length $_))), ($1, $2, $3);
  }
  else {
    eval {
      (@rgb) = $self->LookupColor($self->{default_colormap}, $spec);
      # TODO: handle error?
      splice(@rgb, 0, 3);
    };
  }
  $pixel = $self->{color_helper}->(@rgb);
  if (!defined $pixel) {
    warn "color_to_pixel: failed for '$spec' (@rgb)\n";
    $pixel = $self->{white_pixel};
  }

  return ($pixel, \@rgb);
}

############################################################################

1;
