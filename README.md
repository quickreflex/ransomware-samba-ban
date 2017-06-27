# Ransomware Samba Ban

Bash script to detect ransomware activity and ban client IP address from samba file server.

## Requirements

For proper work, it is required:
* Netfilter/Iptables - http://www.netfilter.org
* inotify-tools - https://github.com/rvoicilas/inotify-tools

## Installation

There is also a sample smb.conf file for reference

* Configure full accounting in samba adding the following entries to the [global] section

```
   # Anti-ransomware
   full_audit: failure = none
   full_audit: success = pwrite write rename
   full_audit: prefix = IP=%I|USER=%u|MACHINE=%m|VOLUME=%S
   full_audit: facility = local7
   full_audit: priority = NOTICE
```

* Add the following entry to all shared folders 

```
    # Option to enable audit for ransomware detection
    vfs objects = full_audit
```

