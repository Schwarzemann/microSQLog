# microSQLog
This is a small modular Perl monitor intended to run as a systemd daemon. It discovers installed MySQL/MariaDB systemd services, periodically checks whether they are active, restarts crashed or stopped instances, and logs only critical events.
