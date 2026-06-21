# μSQLog

This is a small modular Perl monitor intended to run as a `systemd` daemon. It discovers installed MySQL/MariaDB systemd services, periodically checks whether they are active, restarts crashed or stopped instances, and logs only critical events.

## Install

Clone the repository on the target server:

```sh
git clone https://github.com/Schwarzemann/microSQLog.git
cd microSQLog
```

Install the service files:

```sh
sudo install -d /usr/local/lib/microsqlog /usr/local/sbin /etc/microsqlog /etc/systemd/system
sudo cp -r lib/MicroSQLog /usr/local/lib/microsqlog/
sudo cp bin/microsqlog.pl /usr/local/sbin/microsqlog.pl
sudo cp etc/microsqlog.conf /etc/microsqlog/microsqlog.conf
sudo cp systemd/microsqlog.service /etc/systemd/system/microsqlog.service
sudo chmod 0755 /usr/local/sbin/microsqlog.pl
sudo chmod 0750 /etc/microsqlog
sudo chmod 0640 /etc/microsqlog/microsqlog.conf
```

Enable and start the daemon:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now microsqlog.service
sudo systemctl status microsqlog.service
```

## Config

By default the daemon discovers systemd units whose service names contain `mysql` or `mariadb`.

For explicit instances, set a comma-separated list:

```ini
managed_units = mysql.service,mariadb@customer-a.service,mariadb@customer-b.service
```

Other settings:

```ini
check_interval_seconds = 30
restart_grace_seconds = 8
journal_lines = 80
log_file = /etc/microsqlog/critical.log
```
