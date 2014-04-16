#!/bin/bash
tail -n 1000 /var/log/syslog | perl -e 'print reverse <>' >/var/www/logs/syslog
tail -n 1000 /var/log/auth.log | perl -e 'print reverse <>' >/var/www/logs/auth.log



