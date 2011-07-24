#!perl
use strict;
use warnings;

use PocketIO;
use Plack::Builder;
use IO::Handle;
use Term::ReadKey qw(ReadMode ReadKey);
STDOUT->autoflush();

ReadMode 'raw';
END{ ReadMode 'restore' }

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
            while (my $key = ReadKey(0)) {
                if( $key eq "\cC" ) {
                    die "Interrupt!\n";
                }
                elsif( $key eq 'q' ) {
                    exit;
                }
                print "<$key>";
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
