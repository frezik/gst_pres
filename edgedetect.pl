#!/usr/bin/perl
use v5.14;
use warnings;
use GStreamer1;
use Glib qw( TRUE FALSE );

use constant INPUT => '/dev/video0';


sub bus_error_callback
{
    my ($bus, $msg, $loop) = @_;
    my $s = $msg->get_structure;
    warn $s->get_value('gerror')->message . "\n";
    $loop->quit;
    return FALSE;
}


{
    my $loop = Glib::MainLoop->new( undef, FALSE );
    GStreamer1::init([ $0, @ARGV ]);

    my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );
    my $v4l2src = GStreamer1::ElementFactory::make( v4l2src => 'and_who');
    my $capsfilter = GStreamer1::ElementFactory::make(
        capsfilter => 'are_you' );
    my $vidconvert1 = GStreamer1::ElementFactory::make(
        videoconvert => 'the_proud_lord_said' );
    my $edgedetect = GStreamer1::ElementFactory::make(
        edgedetect => 'that_i_should_bow_so_low' );
    my $vidconvert2 = GStreamer1::ElementFactory::make(
        videoconvert => 'only_a_cat' );
    my $xvimagesink = GStreamer1::ElementFactory::make(
        xvimagesink => 'of_a_different_coat' );

    my $caps = GStreamer1::Caps::Simple->new( 'video/x-raw',
        width     => 'Glib::Int'    => 320,
        height    => 'Glib::Int'    => 240,
        #framerate => 'Glib::Double' => (30/1),
    );
    $capsfilter->set( caps => $caps );

    $v4l2src->set(
        device => INPUT,
    );

    $pipeline->add( $_ ) for
        $v4l2src,
        $capsfilter,
        $vidconvert1,
        $edgedetect,
        $vidconvert2,
        $xvimagesink;

    $v4l2src->link( $capsfilter );
    $capsfilter->link( $vidconvert1 );
    $vidconvert1->link( $edgedetect );
    $edgedetect->link( $vidconvert2 );
    $vidconvert2->link( $xvimagesink );

    my $bus = $pipeline->get_bus;
    $bus->add_signal_watch;
    $bus->signal_connect( 'message::error', \&bus_error_callback, $loop );

    $pipeline->set_state( 'playing' );
    $loop->run;
    $pipeline->set_state( 'null' );
}
