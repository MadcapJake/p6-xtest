unit module SDL;

use NativeCall;

sub xtest-lib() { '/usr/include/X11/extensions/XTest.h' }
sub x11-lib() { '/usr/include/X11/Xlib.h' }

=head X11 XLib routines

class Display is repr('CPointer') { }

constant KeySym  = uint32;
constant KeyCode = uint8;
constant NoSymbol = 0;

sub open-display(Str)
    returns Display
    is native(&x11-lib)
    is symbol('XOpenDisplay')
    { * }

sub close-display(Display)
    returns int32
    is native(&x11-lib)
    is symbol('XCloseDisplay')
    { * }

sub flush-display(Display)
    returns int32
    is native(&x11-lib)
    is symbol('XFlush')
    { * }

sub string-to-keysym(Str)
    returns KeySym
    is native(&x11-lib)
    is symbol('XStringToKeysym')
    { * }

sub keysym-to-keycode(Display, uint32)
    returns KeyCode
    is native(&x11-lib)
    is symbol('XKeysymToKeycode')
    { * }

sub keycode(Display $dpy, Str:D $key) {
  my $ks = string-to-keysym($key);
  if $ks == NoSymbol { die "no symbol for key {$key}" }
  return keysym-to-keycode($dpy, $ks);
}

=head X11 XTest extension routines

our sub fake-key-event(Display, uint32, Bool, ulong)
    returns int32
    is native(&xtest-lib)
    is symbol('XTestFakeKeyEvent')
    { * }

our sub fake-button-event(Display, uint32, Bool, ulong)
    returns int32
    is native(&xtest-lib)
    is symbol('XTestFakeButtonEvent')
    { * }

our sub fake-motion-event(Display, uint32, uint32, uint32, ulong)
    returns int32
    is native(&xtest-lib)
    is symbol('XTestFakeMotionEvent')
    { * }

our sub fake-relative-motion-event(Display, uint32, uint32, ulong)
    returns int32
    is native(&xtest-lib)
    is symbol('XTestFakeRelativeMotionEvent')
    { * }

=head XTest Perl 6 class

class XTest {
  has Display $!display;
  has KeyCode @!presses;

  submethod BUILD(Str $display-str = ':0.0') {
    $!display = open-display($display-str);
    without $!display { die "unable to open display {$display-str}" }
  }

  method close() { close-display($.display) }

  proto method key-event(Str:D $key) {
    given $key {
      when $_ eq '-'   { $key = 'minus' }
      when $_ eq $_.uc { $key = "Shift-{$_}" }
    }
    for $key.split('-') {
      $_ += '_L' if $_ eq any ['Shift', 'Alt', 'Control'];
      append @!presses, keycode($!display, $_);
    }
    { * }
  }
  multi method key-event(Str:D $key, :$up) {
    for @!presses { fake-key-event($!display, $_, True,  0) }
    flush-display($!display);
  }
  multi method key-event(Str:D $key, :$down) {
    for @!presses { fake-key-event($!display, $_, False, 0) }
    flush-display($!display);
  }
}
