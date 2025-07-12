# Systemd Fundamentals

## What is Systemd?

Systemd is a system and service manager for Linux operating systems. It's designed to be backwards compatible with SysV init scripts and provides many powerful features for managing services, mount points, devices, and other system resources.

## Key Features

### Service Management
- **Unit Files:** Configuration files that define how services should run
- **Dependencies:** Services can depend on other services or system states
- **Automatic Restart:** Services can be configured to restart on failure
- **Resource Control:** Integration with cgroups for resource management

### System States
- **Targets:** Equivalent to runlevels, define system states
- **Boot Process:** Manages the entire boot sequence
- **Shutdown:** Handles graceful system shutdown

## Core Concepts

### Unit Types
- **service**: Manages daemons and background processes
- **target**: Groups units together (like runlevels)
- **mount**: Manages filesystem mount points
- **timer**: Scheduler (like cron)
- **socket**: Socket-based activation
- **device**: Device management

### Unit File Structure
```ini
[Unit]
Description=My Service Description
After=network.target

[Service]
Type=simple
ExecStart=/path/to/executable
Restart=always

[Install]
WantedBy=multi-user.target
```

## Essential Commands

### Service Management
```bash
# Start a service
systemctl start service-name

# Stop a service
systemctl stop service-name

# Restart a service
systemctl restart service-name

# Check service status
systemctl status service-name

# Enable service for boot
systemctl enable service-name

# Disable service from boot
systemctl disable service-name

# Reload systemd configuration
systemctl daemon-reload
```

### Logging and Monitoring
```bash
# View service logs
journalctl -u service-name

# Follow logs in real-time
journalctl -u service-name -f

# View system logs
journalctl

# View logs since last boot
journalctl -b
```

## Service Types

### Type=simple (Default)
- Process runs in foreground
- Doesn't fork/daemonize
- Main process is the service

### Type=forking
- Service forks and parent exits
- Traditional daemon behavior
- Requires PIDFile usually

### Type=oneshot
- Process runs once and exits
- Good for initialization scripts
- Often used with RemainAfterExit=yes

### Type=notify
- Service sends readiness notification
- Uses sd_notify() function
- More reliable startup detection

## Unit File Locations

### System Units
- `/lib/systemd/system/` - Distribution-provided units
- `/etc/systemd/system/` - Local system units (highest priority)
- `/run/systemd/system/` - Runtime units

### User Units
- `~/.config/systemd/user/` - User-specific units
- `/etc/systemd/user/` - System-wide user units

### Priority Order
1. `/etc/systemd/system/`
2. `/run/systemd/system/`
3. `/lib/systemd/system/`

## Common Configuration Options

### [Unit] Section
```ini
Description=Human readable description
Documentation=man:myservice(8)
Requires=dependency.service
Wants=optional-dependency.service
After=network.target
Before=shutdown.target
```

### [Service] Section
```ini
Type=simple|forking|oneshot|notify
User=username
Group=groupname
ExecStart=/path/to/command
ExecReload=/path/to/reload-command
ExecStop=/path/to/stop-command
Restart=always|on-failure|no
RestartSec=5
Environment=VAR=value
WorkingDirectory=/path/to/workdir
```

### [Install] Section
```ini
WantedBy=multi-user.target
RequiredBy=some-service.service
Alias=alternative-name.service
```

## Targets (Runlevels)

### Common Targets
- `poweroff.target` - Shutdown (runlevel 0)
- `rescue.target` - Single user mode (runlevel 1)
- `multi-user.target` - Multi-user, no GUI (runlevel 3)
- `graphical.target` - Multi-user with GUI (runlevel 5)
- `reboot.target` - Restart (runlevel 6)

### Target Commands
```bash
# Change to different target
systemctl isolate multi-user.target

# Set default target
systemctl set-default graphical.target

# Get default target
systemctl get-default
```

## Troubleshooting

### Common Issues
1. **Service won't start**
   - Check `systemctl status service-name`
   - View logs with `journalctl -u service-name`
   - Verify file permissions
   - Check syntax of unit file

2. **Service keeps restarting**
   - Script exits instead of running continuously
   - Missing dependencies
   - Incorrect service type

3. **Service not starting at boot**
   - Service not enabled: `systemctl enable service-name`
   - Wrong target in WantedBy
   - Dependency issues

### Debugging Commands
```bash
# Check service status
systemctl status service-name

# View detailed logs
journalctl -u service-name -l

# Check unit file syntax
systemd-analyze verify /path/to/service.unit

# List failed services
systemctl --failed

# Check boot time
systemd-analyze

# Check service dependencies
systemctl list-dependencies service-name
```

## Best Practices

### Security
- Run services as non-root users when possible
- Use `PrivateTmp=yes` for temporary file isolation
- Set appropriate file permissions
- Use `NoNewPrivileges=yes` to prevent privilege escalation

### Reliability
- Configure appropriate restart policies
- Set reasonable restart delays
- Use health checks where applicable
- Implement proper logging

### Performance
- Avoid unnecessary dependencies
- Use socket activation for on-demand services
- Configure resource limits with cgroups
- Use systemd timers instead of cron for better integration

## Integration with Other Technologies

### Containers
- Systemd can manage container lifecycles
- Integration with podman for rootless containers
- Service files can start/stop container workloads

### Cgroups
- Automatic cgroup management for services
- Resource limiting and accounting
- Process isolation and organization

### Networking
- Socket activation for network services
- Network dependency management
- Service binding to specific interfaces

## References

- `man systemd`
- `man systemd.service`
- `man systemd.unit`
- `man systemctl`
- `man journalctl`
- [Systemd Documentation](https://systemd.io/)
- [Arch Linux Systemd Wiki](https://wiki.archlinux.org/title/systemd)