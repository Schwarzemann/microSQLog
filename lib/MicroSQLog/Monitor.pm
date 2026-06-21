package MicroSQLog::Monitor;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    return bless {
        config  => $args{config},
        logger  => $args{logger},
        systemd => $args{systemd},
    }, $class;
}

sub run {
    my ($self) = @_;

    while (1) {
        $self->check_once;
        sleep $self->{config}->{check_interval_seconds};
    }
}

sub check_once {
    my ($self) = @_;

    my @units = @{$self->{config}->{managed_units}};
    @units = $self->{systemd}->discover_database_units if !@units;

    if (!@units) {
        $self->{logger}->critical('no_instances_found', 'no mysql/mariadb systemd services discovered');
        return;
    }

    for my $unit (@units) {
        next if $self->{systemd}->is_active($unit);
        $self->_recover_unit($unit);
    }
}

sub _recover_unit {
    my ($self, $unit) = @_;

    my $status_before = $self->{systemd}->status_summary($unit);
    my $reason_before = $self->{systemd}->latest_failure_reason($unit);

    $self->{logger}->critical(
        'instance_down',
        'database service is not active; attempting restart',
        {
            unit   => $unit,
            status => $status_before,
            reason => $reason_before,
        },
    );

    my $restart_started = $self->{systemd}->restart($unit);
    sleep $self->{config}->{restart_grace_seconds};

    if ($restart_started && $self->{systemd}->is_active($unit)) {
        $self->{logger}->critical(
            'restart_succeeded',
            'database service restarted successfully',
            {
                unit   => $unit,
                status => $self->{systemd}->status_summary($unit),
            },
        );
        return;
    }

    $self->{logger}->critical(
        'restart_failed',
        'database service restart failed',
        {
            unit   => $unit,
            status => $self->{systemd}->status_summary($unit),
            reason => $self->{systemd}->latest_failure_reason($unit),
        },
    );
}

1;
