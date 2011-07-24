#!perl
use strict;
use warnings;

use Encode 'decode_utf8';
use Plack::Builder;
use PocketIO;
use Path::Class 'file';
use Amon2::Lite;
use Filesys::Notify::Simple;
use Text::Markdown 'markdown';

shift; # psgi
my $target = shift or die;
-f $target         or die;
$target = file($target);

get '/' => sub {
    my ($c) = @_;
    return $c->render('index.tt');
};

builder {
    mount '/socket.io' => PocketIO->new(
        handler => sub {
            my $self = shift;
            my $watcher = Filesys::Notify::Simple->new(['.']);
            while (1) {
                $watcher->wait(
                    sub {
                        my @events = @_;
                        for my $event (@events) {
                            next if $event->{path} ne $target->absolute;
                            my $text = $target->slurp;
                            $self->send_message({
                                html => decode_utf8(markdown($text)),
                            });
                        }
                    },
                );
            }
        },
    );
    mount '/' => __PACKAGE__->to_app;
};

__DATA__

@@ index.tt
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>preview</title>
    <script type="text/javascript" src="https://raw.github.com/LearnBoost/socket.io-client/master/dist/socket.io.js"></script>
    <script type="text/javascript">
      var socket = io.connect();
      socket.on('message', function (msg) {
        document.getElementById('preview').innerHTML = msg.html
      });
    </script>
  </head>
  <body>
    <div id="preview"></div>
  </body>
</html>
