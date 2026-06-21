package MicroSQLog::Config;

use strict;
use warnings;

sub load {
    my ($class, $path) = @_;

    my $config = {
        check_interval_seconds => 30,
        log_file               => '/etc/microsqlog/critical.log',
        journal_lines          => 80,
        restart_grace_seconds  => 8,
        managed_units          => [],
    };

    return $config if !-e $path;

    open my $fh, '<', $path or die "Cannot open config $path: $!";

    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/#.*$//;
        $line =~ s/^\s+|\s+$//g;
        next if $line eq '';

        my ($key, $value) = split /\s*=\s*/, $line, 2;
        next if !defined $key || !defined $value;

        if ($key eq 'managed_units') {
            my @units = grep { $_ ne '' } map {
                my $unit = $_;
                $unit =~ s/^\s+|\s+$//g;
                $unit;
            } split /,/, $value;
            $config->{$key} = \@units;
            next;
        }

        if ($key =~ /^(check_interval_seconds|journal_lines|restart_grace_seconds)$/) {
            $config->{$key} = int($value);
            next;
        }

        if ($key eq 'log_file') {
            $config->{$key} = $value;
        }
    }

    close $fh;
    return $config;
}

1;
