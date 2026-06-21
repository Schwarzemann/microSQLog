#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib q(/usr/local/lib/microsqlog);

use MicroSQLog::Config;
use MicroSQLog::Logger;
use MicroSQLog::Systemd;
use MicroSQLog::Monitor;

my $config = MicroSQLog::Config->load('/etc/microsqlog/microsqlog.conf');
my $logger = MicroSQLog::Logger->new(
    log_file => $config->{log_file},
);

my $systemd = MicroSQLog::Systemd->new(
    journal_lines => $config->{journal_lines},
);

my $monitor = MicroSQLog::Monitor->new(
    config  => $config,
    logger  => $logger,
    systemd => $systemd,
);

$SIG{TERM} = sub {
    $logger->critical('daemon_stopping', 'received SIGTERM');
    exit 0;
};

$SIG{INT} = sub {
    $logger->critical('daemon_stopping', 'received SIGINT');
    exit 0;
};

$logger->critical('daemon_started', 'mysql/mariadb monitor started');
$monitor->run;
