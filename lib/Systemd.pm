package MicroSQLog::Systemd;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    return bless {
        journal_lines => $args{journal_lines} || 80,
    }, $class;
}

sub discover_database_units {
    my ($self) = @_;

    my %units;

    for my $command (
        [qw(systemctl list-units --type=service --all --no-legend --plain)],
        [qw(systemctl list-unit-files --type=service --no-legend --plain)],
    ) {
        for my $line (_capture(@{$command})) {
            next if $line !~ /^\s*(\S+\.service)\s+/;
            my $unit = $1;
            next if $unit !~ /(?:mysql|mariadb)/i;
            next if $unit =~ /microsqlog/i;
            next if substr($unit, -9) eq q(@.service);
            $units{$unit} = 1;
        }
    }

    return sort keys %units;
}

sub is_active {
    my ($self, $unit) = @_;
    system('systemctl', 'is-active', '--quiet', $unit);
    return $? == 0;
}

sub status_summary {
    my ($self, $unit) = @_;
    my @status = _capture(qw(systemctl show), $unit,
        '--property=Id,ActiveState,SubState,Result,ExecMainStatus,ExecMainCode,NRestarts',
        '--no-page');

    return join('; ', grep { $_ ne '' } @status);
}

sub restart {
    my ($self, $unit) = @_;
    system('systemctl', 'restart', $unit);
    return $? == 0;
}

sub latest_failure_reason {
    my ($self, $unit) = @_;

    my @journal = _capture(
        'journalctl',
        '-u', $unit,
        '-n', $self->{journal_lines},
        '--no-pager',
        '--output=short-iso',
    );

    my @interesting = grep {
        /error|fail|fatal|crash|abort|signal|oom|denied|corrupt|innodb/i
    } @journal;

    my $reason = $interesting[-1] || $journal[-1] || 'no journal details available';
    $reason =~ s/^\s+|\s+$//g;
    return $reason;
}

sub _capture {
    my (@command) = @_;

    open my $fh, '-|', @command or return ();
    my @lines = <$fh>;
    close $fh;

    chomp @lines;
    return @lines;
}

1;
