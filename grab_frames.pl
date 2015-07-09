#!/usr/bin/perl
use v5.14;
use warnings;
use GStreamer1;
use Glib qw( TRUE FALSE );
use Digest::Adler32::XS;

my $FILE = shift or die "Need a file to process\n";

sub bus_error_callback
{
    my ($bus, $msg, $loop) = @_;
    my $s = $msg->get_structure;
    warn $s->get_value('gerror')->message . "\n";
    $loop->quit;
    return FALSE;
}

sub bus_eos_callback
{
    my ($bus, $msg, $loop) = @_;
    say "Got End of Stream";
    $loop->quit;
    return TRUE;
}

sub handoff_callback
{
    my ($fakesink, $buffer, $pad) = @_;
    my $size = $buffer->get_size;
    my $frame_data = $buffer->extract_dup( 0, $size );

    my $digest = Digest::Adler32::XS->new;
    $digest->add( @$frame_data );
    my $checksum = $digest->hexdigest;

    say "Got frame, size: $size, checksum: $checksum";
    return TRUE;
}


{
    my $loop = Glib::MainLoop->new( undef, FALSE );
    GStreamer1::init([ $0, @ARGV ]);

    my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );
    my $filesrc = GStreamer1::ElementFactory::make( filesrc => 'and_who');
    my $capsfilter = GStreamer1::ElementFactory::make(
        capsfilter => 'are_you' );
    my $h264parse = GStreamer1::ElementFactory::make(
        'h264parse' => 'the_proud_lord_said' );
    my $fakesink = GStreamer1::ElementFactory::make(
        fakesink => 'that_i_should_bow_so_low' );


    $filesrc->set(
        location => $FILE,
    );
    my $caps = GStreamer1::Caps::Simple->new( 'video/x-h264',
        width     => 'Glib::Int'    => 640,
        height    => 'Glib::Int'    => 480,
    );
    $capsfilter->set( caps => $caps );

    $fakesink->set(
        'signal-handoffs' => TRUE,
    );

    $pipeline->add( $_ ) for
        $filesrc,
        $capsfilter,
        $h264parse,
        $fakesink;

    $filesrc->link( $capsfilter );
    $capsfilter->link( $h264parse );
    $h264parse->link( $fakesink );

    my $bus = $pipeline->get_bus;
    $bus->add_signal_watch;
    $bus->signal_connect( 'message::error', \&bus_error_callback, $loop );
    $bus->signal_connect( 'message::eos', \&bus_eos_callback, $loop );
    $fakesink->signal_connect( 'handoff', \&handoff_callback );

    $pipeline->set_state( 'playing' );
    $loop->run;
    $pipeline->set_state( 'null' );
}
