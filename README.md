# Description

This role configures a [systemd timer](https://www.freedesktop.org/software/systemd/man/systemd.timer.html) along with a [`oneshot` service](https://www.freedesktop.org/software/systemd/man/systemd.service.html) for running a provided script.

# Configuration

```yml
systemd_timer_name: my-test
systemd_timer_description: 'Just a timer creation test.'
systemd_timer_user: 'root'
systemd_timer_frequency: 'hourly'
systemd_timer_timeout_sec: 120
systemd_timer_nice_priority: 10
systemd_timer_requires_extra: 'network.target'
systemd_timer_after_extra: 'network.target'
systemd_timer_work_dir: '/tmp/somedir'
systemd_timer_environment:
  MY_ENV_VAR: 'some_value'
systemd_timer_script_content: |
  #!/usr/bin/env bash
  echo "My Timer Script!"
```
The `frequency` accepts [systemd time specification](https://www.freedesktop.org/software/systemd/man/systemd.time.html#) format.

## Service User

By default `nobody` is used, but a [dynamic user](https://0pointer.net/blog/dynamic-users-with-systemd.html) is a more secure option:
```
systemd_timer_dynamic_user: yes
```

## State Directory

A state directory in `/var/lib` can be created using:
```yml
systemd_timer_state_dir_create: false
systemd_timer_state_dir: '{{ systemd_timer_name }}'
systemd_timer_state_dir_perms: 0750
```
Which will be named same as the timer itself.

## Automatic Restarts

Automatic restarts with limited retries can also be configured:
```yml
systemd_timer_restart: 'on-failure'
systemd_timer_restart_delay: 60
systemd_timer_restart_retries: 5
```

## Consul Metadata

You can also customize the Consul service definition:
```
systemd_timer_consul_service_id: 'my-test-abc'
systemd_timer_consul_service_name: 'my-test'
systemd_timer_consul_extra_tags: ['test', 'abc']
systemd_timer_consul_meta: { my_meta: 'metadata' }
```
The service runs the [`check.sh`](templates/check.sh.j2) script to verify timer health..

# Usage

The the timer starts the service with configured frequency.
Assuming our backup target is called `database` you can do:
```
 $ sudo systemctl status my-test.service
● my-test.service - Just a timer creation test.
   Loaded: loaded (/lib/systemd/system/my-test.service; static; vendor preset: enabled)
   Active: inactive (dead) since Mon 2020-02-17 13:14:53 UTC; 6s ago
     Docs: https://github.com/status-im/infra-role-systemd-timer
  Process: 26001 ExecStart=/usr/local/bin/my-test (code=exited, status=0/SUCCESS)
 Main PID: 26001 (code=exited, status=0/SUCCESS)

Feb 17 13:14:53 host.example.org systemd[1]: Starting Just a timer creation test....
Feb 17 13:14:53 host.example.org systemd[1]: Started Just a timer creation test..
Feb 17 13:14:53 host.example.org my-test[26001]: My Timer Script!
```

You can check the timer status too:
```
 $ sudo systemctl list-timers my-test.timer     
NEXT                         LEFT       LAST PASSED UNIT          ACTIVATES
Mon 2020-02-17 14:00:00 UTC  44min left n/a  n/a    my-test.timer my-test.service
```
