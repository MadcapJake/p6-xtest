use NativeCall;

sub xtest-lib() { '/usr/lib/x86_64-linux-gnu/libXtst.so' }
sub x11-lib()   { '/usr/lib/x86_64-linux-gnu/libX11.so' }

=head X11 XLib routines

class Display is repr('CPointer') { }

constant KeySym  = uint64;
constant KeyCode = uint8;
constant NoSymbol = 0;

sub open-display(Str)
    returns Display
    is native(&x11-lib)
    is symbol('XOpenDisplay')
    { * }

sub close-display(Display)
    returns int64
    is native(&x11-lib)
    is symbol('XCloseDisplay')
    { * }

sub flush-display(Display)
    returns int64
    is native(&x11-lib)
    is symbol('XFlush')
    { * }

sub string-to-keysym(Str)
    returns KeySym
    is native(&x11-lib)
    is symbol('XStringToKeysym')
    { * }

sub keysym-to-keycode(Display, uint64)
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

our sub fake-key-event(Display, uint64, Bool, ulong)
    returns int64
    is native(&xtest-lib)
    is symbol('XTestFakeKeyEvent')
    { * }

our sub fake-button-event(Display, uint64, Bool, ulong)
    returns int64
    is native(&xtest-lib)
    is symbol('XTestFakeButtonEvent')
    { * }

our sub fake-motion-event(Display, uint64, uint64, uint64, ulong)
    returns int64
    is native(&xtest-lib)
    is symbol('XTestFakeMotionEvent')
    { * }

our sub fake-relative-motion-event(Display, uint64, uint64, ulong)
    returns int64
    is native(&xtest-lib)
    is symbol('XTestFakeRelativeMotionEvent')
    { * }

=head XTest Perl 6 class

class XTest:ver<0.0.1> {
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
