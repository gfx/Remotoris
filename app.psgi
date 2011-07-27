#!perl
# Usage: twiggy app.psgi
use strict;
use warnings;

use PocketIO;
use Plack::Builder;
use IO::Handle;
STDOUT->autoflush();

{
    package ReadKey::Guard;
    use Term::ReadKey qw(ReadMode ReadKey);
    sub new {
        my($class, $mode) = @_;
        ReadMode($mode);
        return bless {}, $class;
    }
    sub readkey {
        my($self, $mode) = @_;
        return ReadKey($mode);
    }
    sub DESTROY {
        ReadMode('restore');
    }
}

sub help {
    return <<'T';
Connection established.
Availale keys: h j k l <space>
T
}

builder {
    mount '/socket.io' => PocketIO->new(
        handler => sub {
            my($self) = @_;
            print help();
            print "->> ";
            my $guard = ReadKey::Guard->new('raw');
            while (my $key = $guard->readkey(0)) {
                print "<$key>";
                if( $key eq "\cC" ) {
                    warn "Interrupt!\n";
                    exit(1);
                }
                elsif( $key eq 'q' ) {
                    exit(0);
                }
                $self->send_message({ key => ord($key) });
            }
        },
    );

    mount '/' =>  sub {
        open my $fh, '<', 'tetoris.html' or die $!;
        return [
            200,
            ['Content-Type' => 'text/html'],
            $fh,
        ];
    };
};
