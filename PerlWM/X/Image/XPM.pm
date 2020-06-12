#
# $Id: XPM.pm,v 1.1.1.1 2002/07/07 11:49:49 rdw Exp $
#

package PerlWM::X::Image::XPM;

############################################################################

use strict;
use warnings;

use IO::File;

############################################################################

sub image_xpm_read {

  my($self, $filename) = @_;

  sub read_strings {
    my($file, $count, $text) = @_;
    my @result;
    while (@result < $count) {
      if ($text && $text =~ s/[^\"]*\"([^\"]+)\"//) {
	push @result, $1;
      }
      else {
	$text = <$file>;
	last unless $text;
        $text =~ s/^[^\"]*\/\*.*?\*\///;
      }
    }
    return \@result;
  }

  return unless my $file = new IO::File("<$filename");

  my $result;
  while (<$file>) {
    chomp;
    if (m{/\* XPM \*/(.*)}) {
      while (<$file>) {
	last if /char.*[\{\[]/;
      }
      my $info = read_strings($file, 1, $_);
      $info->[0] =~ s/^\s+//;
      $info->[0] =~ s/\s+$//;
      @{$result}{qw(width height ncolors cpp 
		    hotx hoty)} = split /\s+/, $info->[0];
      $result->{colors} = read_strings($file, $result->{ncolors});
      $result->{colors} = { map { my $key = substr($_, 0, $result->{cpp}, '');
				  if (/.*\s+c\s+((\S\S+\s*)+)/) {
				    my $color = $1;
				    $color =~ s/\bg4\b.*//;
				    $color =~ tr/A-Z \t/a-z/d;
				    ($key => $color)
				  }
				  else {
				    ($key => 'black');
				  }
				} @{$result->{colors}} };
      $result->{pixels} = read_strings($file, $result->{height});
      last;
    }
    elsif (/\#define (.*)_format\s*1/) {
      my $name = $1;
      while (<$file>) {
	chomp;
	if (/\#define $name\_(width|height|ncolors|chars_per_pixel)\s+(\d+)/) {
	  my($key, $value) = ($1, $2);
	  $key = 'cpp' if $key eq 'chars_per_pixel';
	  $result->{$key} = $value;
	}
        elsif (/$name\_(colors|pixels)\[.*\](.*)/) {
          my($type, $text) = ($1, $2);
	  if ($type eq 'colors') {
	    $result->{colors} = read_strings($file, $result->{ncolors} * 2);
	    $result->{colors} = { @{$result->{colors}} };
	  }
	  elsif ($type eq 'pixels') {
	    $result->{pixels} = read_strings($file, $result->{height});
	  }
	}
      }
      last;
    }
  }
  $file->close();
  return $result;
}

############################################################################

sub image_xpm_load { 

  my($self, $filename) = @_;

  return unless my $xpm = $self->image_xpm_read($filename);

  my $pixmap = $self->new_rsrc;
  $self->CreatePixmap($pixmap, $self->{root}, $self->{root_depth}, 
		      $xpm->{width}, $xpm->{height});

  # TODO: mask!
  s/^(none|transparent)$/black/i for values %{$xpm->{colors}};

  $_ = $self->color_get(undef, $_) for values %{$xpm->{colors}};

  my $depth = $self->{root_depth};

  my $pad = $self->{pixmap_formats}->{$depth}->{scanline_pad} / 8;
  # TODO: different depths / bits_per_pixel
  my $scanline = ($xpm->{width} * 2);
  if (my $odd = $scanline % $pad) {
    $pad = ($pad - $odd);
  }
  else {
    $pad = 0;
  }

  my $y = 0;
  my $height = 0;
  my $max = (($self->{maximum_request_length} * 4) - 32) - $scanline;

  my $gc = $self->gc_get('default');

  my $raw;
  foreach my $row (@{$xpm->{pixels}}) {
    my @data;
    for (my $c = 0; $c < ($xpm->{cpp} * $xpm->{width}); $c += $xpm->{cpp}) {
      push @data, $xpm->{colors}->{substr($row, $c, $xpm->{cpp})};
    }
    # TODO: different depths / endians
    $raw .= pack("s*x$pad", @data);
    $height++;
    if (length($raw) > $max) {
      $self->PutImage($pixmap, $gc, $self->{root_depth},
		      $xpm->{width}, $height,
		      (0, $y), 0, 'ZPixmap', $raw);
      $y += $height;
      $height = 0;
      $raw = "";
    }
  }
  
  if ($height) {
    $self->PutImage($pixmap, $gc, $self->{root_depth},
		 $xpm->{width}, $height, 
		 (0, $y), 0, 'ZPixmap', $raw);
  }

  return ($pixmap, { width => $xpm->{width}, height => $xpm->{height} });
}

############################################################################

1;
