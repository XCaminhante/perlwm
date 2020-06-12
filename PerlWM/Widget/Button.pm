#
# $Id: Button.pm,v 1.4 2004/02/16 10:51:08 rdw Exp $
#

package PerlWM::Widget::Button;

############################################################################

use strict;
use warnings;

use base qw(PerlWM::Widget::Label);

############################################################################

sub onClick {

  my($self, $event) = @_;
  if ($self->{action}) {
    $self->{action}->($self);
  }
}

############################################################################

sub EVENT { (__PACKAGE__->SUPER::EVENT,
	     'Click(Button1)' => 'onClick') }

############################################################################

1;
