# Ransomware Samba Ban

This is bash script to detect ransomware activity and ban infected IP address to protect us from files encryption at samba server.

## Requirements

For proper work, it is required:
* Netfilter/Iptables - http://www.netfilter.org
* inotify-tools - https://github.com/rvoicilas/inotify-tools
* curl - https://curl.haxx.se
* jq - https://stedolan.github.io/jq/

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

## How it works

Basically, what it does is enable full audit in Samba server and monitor the logs for known ransomware extensions and file names. When detect a ransomware activity, it ban infected IP address to protect us from files encryption at samba server.
