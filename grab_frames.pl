#!/usr/bin/perl
use v5.14;
use warnings;
use GStreamer1;
use Glib qw( TRUE FALSE );

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
DEBUG: $DB::single = 1;
    say "Got frame, size: " . $buffer->get_size;
    return TRUE;
}


{
    my $loop = Glib::MainLoop->new( undef, FALSE );
    GStreamer1::init([ $0, @ARGV ]);

    my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );
    my $filesrc = GStreamer1::ElementFactory::make( filesrc => 'and_who');
    my $fakesink = GStreamer1::ElementFactory::make(
        fakesink => 'are_you' );

    $filesrc->set(
        location => $FILE,
    );
    $fakesink->set(
        'signal-handoffs' => TRUE,
    );

    $pipeline->add( $_ ) for
        $filesrc,
        $fakesink;

    $filesrc->link( $fakesink );

    my $bus = $pipeline->get_bus;
    $bus->add_signal_watch;
    $bus->signal_connect( 'message::error', \&bus_error_callback, $loop );
    $bus->signal_connect( 'message::eos', \&bus_eos_callback, $loop );
    $fakesink->signal_connect( 'handoff', \&handoff_callback );

    $pipeline->set_state( 'playing' );
    $loop->run;
    $pipeline->set_state( 'null' );
}
