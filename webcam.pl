#!/usr/bin/perl
use v5.14;
use warnings;
use GStreamer1;
use Glib qw( TRUE FALSE );

use constant INPUT => '/dev/video0';


sub bus_callback
{
    my ($bus, $msg, $loop) = @_;

    if( $msg->type & "error" ) {
        warn $msg->error;
        $loop->quit;
    }
    elsif( $msg->type & "eos" ) {
        warn "End of stream, quitting\n";
        $loop->quit;
    }

    return TRUE;
}


{
    my $loop = Glib::MainLoop->new( undef, FALSE );
    GStreamer1::init([ $0, @ARGV ]);

    my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );
    my $v4l2src = GStreamer1::ElementFactory::make( v4l2src => 'and_who');
    #my $capsfilter = GStreamer1::ElementFactory::make(
    #    capsfilter => 'are_you' );
    my $xvimagesink = GStreamer1::ElementFactory::make(
        xvimagesink => 'the_proud_lord_said' );

    #my $caps = GStreamer1::Caps::Simple->new( 'video/x-raw',
    #    width     => 'Glib::Int'    => 640,
    #    height    => 'Glib::Int'    => 480,
    #    framerate => 'Glib::Double' => (30/1),
    #);
    #$capsfilter->set( caps => $caps );

    $v4l2src->set(
        device => INPUT,
    );

    $pipeline->add( $_ ) for
        $v4l2src,
        #$capsfilter,
        $xvimagesink;

    $v4l2src->link( $xvimagesink );
    #$v4l2src->link( $capsfilter );
    #$capsfilter->link( $xvimagesink );

    my $bus = $pipeline->get_bus;
    $bus->add_signal_watch;
    $bus->add_watch( \&bus_callback, $loop );

    $pipeline->set_state( 'playing' );
    $loop->run;
    $pipeline->set_state( 'null' );
}
