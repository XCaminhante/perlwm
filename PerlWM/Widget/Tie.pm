#
# $Id: Tie.pm,v 1.1 2002/07/14 01:25:33 rdw Exp $
# 

############################################################################

package PerlWM::Widget::Tie;

use strict;
use warnings;

sub NOTIFY	{ $_[0]->[1]->($_[0]->[2], $_[0]->[0]); 
		  wantarray ? (@{$_[1]}) : $_[1]->[0] }

############################################################################

package PerlWM::Widget::Tie::Scalar;

use strict;
use warnings;

use base qw(PerlWM::Widget::Tie);

sub TIESCALAR	{ bless [@_[1..3]], $_[0] }
sub STORE	{ $_[0]->NOTIFY([$_[0]->[0] = $_[1]]) }
sub FETCH	{ $_[0]->[0] }
sub DESTROY	{ undef $_[0]->[0] }

############################################################################

package PerlWM::Widget::Tie::Array;

use strict;
use warnings;

use base qw(PerlWM::Widget::Tie);

sub TIEARRAY  { bless [@_[1..3]], $_[0] }
sub FETCHSIZE { scalar @{$_[0]->[0]} }
sub STORESIZE { $_[0]->NOTIFY([$#{$_[0]->[0]} = $_[1]-1]) }
sub STORE     { $_[0]->NOTIFY([$_[0]->[0]->[$_[1]] = $_[2]]) }
sub FETCH     { $_[0]->[0]->[$_[1]] }
sub CLEAR     { $_[0]->NOTIFY([@{$_[0]->[0]} = ()]) }
sub POP       { $_[0]->NOTIFY([pop(@{$_[0]->[0]})]) }
sub PUSH      { my $o = shift; $o->NOTIFY([push(@{$o->[0]},@_)]) }
sub SHIFT     { $_[0]->NOTIFY([shift(@{$_[0]->[0]})]) }
sub UNSHIFT   { my $o = shift; $o->NOTIFY([unshift(@{$o->[0]},@_)]) }
sub EXISTS    { exists $_[0]->[0]->[$_[1]] }
sub DELETE    { $_[0]->NOTIFY([delete $_[0]->[0]->[$_[1]]]) }
sub SPLICE    { my $ob  = shift;
		my $sz  = $ob->FETCHSIZE;
		my $off = @_ ? shift : 0;
		$off   += $sz if $off < 0;
		my $len = @_ ? shift : $sz-$off;
		$ob->NOTIFY([splice(@{$ob->[0]},$off,$len,@_)]); }
sub EXTEND    { }
sub DESTROY   { undef $_[0]->[0] }

############################################################################

1;

