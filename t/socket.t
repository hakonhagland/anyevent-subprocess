use strict;
use warnings;
use Test::More tests => 2;

use AnyEvent::Subprocess;

my $proc = AnyEvent::Subprocess->new(
    code => sub {
        my $done = AnyEvent->condvar;
        my $socket = shift;
        $socket->push_read( json => sub {
            my ($handle, $obj) = @_;
            $socket->push_write( json => {
                cmd => 'echo',
                msg => $obj->{msg},
            });
            $done->send;
        });
        $done->recv;
    },
);

my $run = $proc->run;

my $complete = $run->completion_condvar;

$run->comm_handle->push_write( json => {
    cmd => 'echo',
    msg => 'hello my child',
});

my $got_response = AnyEvent->condvar;

$run->comm_handle->push_read( json => sub {
    my ($handle, $obj) = @_;
    $got_response->send( $obj->{msg} );
});

is $got_response->recv, 'hello my child', 'got echo reply';

my $done = $complete->recv;
is $done->exit_status, 0, 'got exit status 0';
