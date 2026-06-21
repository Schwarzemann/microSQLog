package MicroSQLog::Logger;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use POSIX qw(strftime);

sub new {
    my ($class, %args) = @_;

    my $self = {
        log_file => $args{log_file},
    };

    bless $self, $class;
    $self->_ensure_log_path;
    return $self;
}

sub critical {
    my ($self, $event, $message, $fields) = @_;
    $fields ||= {};

    my $timestamp = strftime('%Y-%m-%dT%H:%M:%S%z', localtime);
    my @parts = (
        "timestamp=$timestamp",
        'level=CRITICAL',
        "event=" . _sanitize($event),
        "message=\"" . _sanitize($message) . "\"",
    );

    for my $key (sort keys %{$fields}) {
        push @parts, _sanitize($key) . '="' . _sanitize($fields->{$key}) . '"';
    }

    open my $fh, '>>', $self->{log_file} or die "Cannot write log $self->{log_file}: $!";
    print {$fh} join(' ', @parts), "\n";
    close $fh;
}

sub _ensure_log_path {
    my ($self) = @_;

    my $dir = dirname($self->{log_file});
    make_path($dir, { mode => 0750 }) if !-d $dir;

    if (!-e $self->{log_file}) {
        open my $fh, '>', $self->{log_file} or die "Cannot create log $self->{log_file}: $!";
        close $fh;
        chmod 0640, $self->{log_file};
    }
}

sub _sanitize {
    my ($value) = @_;
    $value = '' if !defined $value;
    $value =~ s/[\r\n]+/ /g;
    $value =~ s/"/'/g;
    return $value;
}

1;
