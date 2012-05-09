[
  {
    'class_description' => 'Configuration class used by L<Config::Model> to edit or 
validate /etc/ssh/sshd_config
',
    'accept' => [
      '.*',
      {
        'value_type' => 'uniline',
        'summary' => 'boilerplate parameter that may hide a typo',
        'warn' => 'Unknow parameter please make sure there\'s no typo and contact the author',
        'type' => 'leaf'
      }
    ],
    'name' => 'Sshd',
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'AcceptEnv',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies what environment variables sent by the client will be copied into the session\'s environ(7).'
      },
      'AddressFamily',
      {
        'value_type' => 'enum',
        'upstream_default' => 'any',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies which address family should be used by sshd(8).',
        'choice' => [
          'any',
          'inet',
          'inet6'
        ]
      },
      'AllowGroups',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Login is allowed only for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.'
      },
      'AllowUsers',
      {
        'level' => 'important',
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list',
        'description' => 'List of user name patterns, separated by spaces. If specified, login is allowed only for user names that match one of the patterns. Only user names are valid; a numerical user ID is not recognized. By default, login is allowed for all users. If the pattern takes the form USER@HOST then USER and HOST are separately checked, restricting logins to particular users from particular hosts. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.'
      },
      'AllowTcpForwarding',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether TCP forwarding is permitted. The default is "yes".Note that disabling TCP forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'AuthorizedKeysFile2',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'status' => 'deprecated',
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.'
      },
      'AuthorizedKeysFile',
      {
        'migrate_keys_from' => '- AuthorizedKeysFile2',
        'cargo' => {
          'value_type' => 'uniline',
          'migrate_from' => {
            'formula' => '$keysfile2',
            'variables' => {
              'keysfile2' => '- AuthorizedKeysFile2:&index()'
            }
          },
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.'
      },
      'Banner',
      {
        'value_type' => 'uniline',
        'type' => 'leaf',
        'description' => 'In some jurisdictions, sending a warning message before authentication may be relevant for getting legal protection. The contents of the specified file are sent to the remote user before authentication is allowed. This option is only available for protocol version 2. By default, no banner is displayed.'
      },
      'ChallengeResponseAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether challenge-response authentication is allowed. All authentication styles from login.conf(5) are supported.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'Ciphers',
      {
        'experience' => 'master',
        'upstream_default_list' => [
          '3des-cbc',
          'aes128-cbc',
          'aes128-ctr',
          'aes192-cbc',
          'aes192-ctr',
          'aes256-cbc',
          'aes256-ctr',
          'arcfour',
          'arcfour128',
          'arcfour256',
          'blowfish-cbc',
          'cast128-cbc'
        ],
        'type' => 'check_list',
        'description' => 'Specifies the ciphers allowed for protocol version 2. By default, all ciphers are allowed.',
        'choice' => [
          '3des-cbc',
          'aes128-cbc',
          'aes192-cbc',
          'aes256-cbc',
          'aes128-ctr',
          'aes192-ctr',
          'aes256-ctr',
          'arcfour128',
          'arcfour256',
          'arcfour',
          'blowfish-cbc',
          'cast128-cbc'
        ]
      },
      'ClientAliveCountMax',
      {
        'value_type' => 'integer',
        'min' => '1',
        'upstream_default' => '3',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Sets the number of client alive messages which may be sent without sshd(8) receiving any messages back from the client. If this threshold is reached while client alive messages are being sent, sshd will disconnect the client, terminating the session.  It is important to note that the use of client alive messages is very different from TCPKeepAlive. The client alive messages are sent through the encrypted channel and therefore will not be spoofable. The TCP keepalive option enabled by TCPKeepAlive is spoofable. The client alive mechanism is valuable when the client or server depend on knowing when a connection has become inactive.

The default value is 3. If ClientAliveInterval is set to 15, and ClientAliveCountMax is left at the default, unresponsive SSH clients will be disconnected after approximately 45 seconds. This option applies to protocol version 2 only.'
      },
      'ClientAliveInterval',
      {
        'value_type' => 'integer',
        'min' => '1',
        'experience' => 'advanced',
        'type' => 'leaf'
      },
      'Compression',
      {
        'value_type' => 'enum',
        'upstream_default' => 'delayed',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether compression is allowed, or delayed until the user has authenticated successfully.',
        'choice' => [
          'yes',
          'delayed',
          'no'
        ]
      },
      'DenyGroups',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'This keyword can be followed by a list of group name patterns, separated by spaces.  Login is disallowed for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups.  The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.'
      },
      'DenyUSers',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'This keyword can be followed by a list of user name patterns, separated by spaces.  Login is disallowed for user names that match one of the patterns. Only user names are valid; a numerical user ID is not recognized. By default, login is allowed for all users. If the pattern takes the form USER@HOST then USER and HOST are separately checked, restricting logins to particular users from particular hosts. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.'
      },
      'ForceCommand',
      {
        'value_type' => 'uniline',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Forces the execution of the command specified by ForceCommand, ignoring any command supplied by the client. The command is invoked by using the user\'s login shell with the -c option. This applies to shell, command, or subsystem execution. It is most useful inside a Match block. The command originally supplied by the client is available in the SSH_ORIGINAL_COMMAND environment variable.'
      },
      'GatewayPorts',
      {
        'value_type' => 'enum',
        'help' => {
          'yes' => 'force remote port forwardings to bind to the wildcard address',
          'clientspecified' => 'allow the client to select the address to which the forwarding is bound',
          'no' => 'No port forwarding
'
        },
        'upstream_default' => 'no',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether remote hosts are allowed to connect to ports forwarded for the client. By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.',
        'choice' => [
          'yes',
          'clientspecified',
          'no'
        ]
      },
      'GSSAPIAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether user authentication based on GSSAPI is allowed. Note that this option applies to protocol version 2 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'GSSAPIKeyExchange',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether key exchange based on GSSAPI is allowed. GSSAPI key exchange doesn\'t rely on ssh keys to verify host identity. Note that this option applies to protocol version 2 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'GSSAPICleanupCredentials',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether to automatically destroy the user\'s credentials cache on logout. Note that this option applies to protocol version 2 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'GSSAPIStrictAcceptorCheck',
      {
        'value_type' => 'enum',
        'help' => {
          'yes' => 'the client must authenticate against the host service on the current hostname.',
          'no' => 'the client may authenticate against any service key stored in the machine\'s default store'
        },
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Determines whether to be strict about the identity of the GSSAPI acceptor a client authenticates against.This facility is provided to assist with operation on multi homed machines. Note that this option applies only to protocol version 2 GSSAPI connections, and setting it to "no" may only work with recent Kerberos GSSAPI libraries.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'HostbasedAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether rhosts or /etc/hosts.equiv authentication together with successful public key client host authentication is allowed (host-based authentication). This option is similar to RhostsRSAAuthentication and applies to protocol version 2 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'HostbasedUsesNameFromPacketOnly',
      {
        'value_type' => 'enum',
        'help' => {
          'yes' => 'sshd(8) uses the name supplied by the client',
          'no' => 'sshd(8) attempts to resolve the name from the TCP connection itself.'
        },
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether or not the server will attempt to perform a reverse name lookup when matching the name in the ~/.shosts, ~/.rhosts, and /etc/hosts.equiv files during HostbasedAuthentication.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'HostKey',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies a file containing a private host key used by SSH. The default is /etc/ssh/ssh_host_key for protocol version 1, and /etc/ssh/ssh_host_rsa_key and /etc/ssh/ssh_host_dsa_key for protocol version 2. Note that sshd(8) will refuse to use a file if it is group/world-accessible.  It is possible to have multiple host key files. "rsa1" keys are used for version 1 and "dsa" or "rsa" are used for version 2 of the SSH protocol.'
      },
      'IgnoreRhosts',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies that .rhosts and .shosts files will not be used in RhostsRSAAuthentication or HostbasedAuthentication. /etc/hosts.equiv and /etc/ssh/shosts.equiv are still used. ',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'IgnoreUserKnownHosts',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should ignore the user\'s ~/.ssh/known_hosts during RhostsRSAAuthentication or HostbasedAuthentication.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'KbdInteractiveAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'No doc found in sshd documentation',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'KerberosAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether the password provided by the user for PasswordAuthentication will be validated through the Kerberos KDC. To use this option, the server needs a Kerberos servtab which allows the verification of the KDC\'s identity. The default is "no".',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'KerberosGetAFSToken',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'If AFS is active and the user has a Kerberos 5 TGT, attempt to acquire an AFS token before accessing the user\'s home directory.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'KerberosOrLocalPasswd',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'If password authentication through Kerberos fails then the password will be validated via any additional local mechanism such as /etc/passwd.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'KerberosTicketCleanup',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether to automatically destroy the user\'s ticket cache file on logout.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'KeyRegenerationInterval',
      {
        'value_type' => 'integer',
        'upstream_default' => '3600',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'In protocol version 1, the ephemeral server key is automatically regenerated after this many seconds (if it has been used). The purpose of regeneration is to prevent decrypting captured sessions by later breaking into the machine and stealing the keys. The key is never stored anywhere. If the value is 0, the key is never regenerated. The default is 3600 (seconds).'
      },
      'Port',
      {
        'value_type' => 'integer',
        'upstream_default' => '22',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies the port number that sshd(8) listens on. The default is 22. Multiple options of this type are permitted. See also ListenAddress.'
      },
      'ListenAddress',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies the local addresses sshd(8) should listen on. The following forms may be used:

  host|IPv4_addr|IPv6_addr
  host|IPv4_addr:port
  [host|IPv6_addr]:port

If port is not specified, sshd will listen on the address and all prior Port options specified. The default is to listen on all local addresses.  Multiple ListenAddress options are permitted. Additionally, any Port options must precede this option for non-port qualified addresses.'
      },
      'LoginGraceTime',
      {
        'value_type' => 'integer',
        'upstream_default' => '120',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'The server disconnects after this time if the user has not successfully logged in. If the value is 0, there is no time limit. The default is 120 seconds.'
      },
      'LogLevel',
      {
        'value_type' => 'enum',
        'help' => {
          'DEBUG' => 'Logging with this level violates the privacy of users and is not recommended',
          'DEBUG1' => 'Logging with this level violates the privacy of users and is not recommended',
          'DEBUG3' => 'Logging with this level violates the privacy of users and is not recommended',
          'DEBUG2' => 'Logging with this level violates the privacy of users and is not recommended'
        },
        'upstream_default' => 'INFO',
        'type' => 'leaf',
        'choice' => [
          'SILENT',
          'QUIET',
          'FATAL',
          'ERROR',
          'INFO',
          'VERBOSE',
          'DEBUG',
          'DEBUG1',
          'DEBUG2',
          'DEBUG3'
        ]
      },
      'MACs',
      {
        'experience' => 'master',
        'type' => 'check_list',
        'description' => 'Specifies the available MAC (message authentication code) algorithms. The MAC algorithm is used in protocol version 2 for data integrity protection.',
        'choice' => [
          'hmac-md5',
          'hmac-md5-96',
          'hmac-ripemd160',
          'hmac-sha1',
          'hmac-sha1-96',
          'umac-64@openssh.com'
        ]
      },
      'MaxAuthTries',
      {
        'value_type' => 'integer',
        'upstream_default' => '6',
        'type' => 'leaf',
        'description' => 'Specifies the maximum number of authentication attempts permitted per connection. Once the number of failures reaches half this value, additional failures are logged.'
      },
      'MaxStartups',
      {
        'value_type' => 'uniline',
        'upstream_default' => '10',
        'type' => 'leaf',
        'description' => 'Specifies the maximum number of concurrent unauthenticated connections to the SSH daemon. Additional connections will be dropped until authentication succeeds or the LoginGraceTime expires for a connection. The default is 10.

Alternatively, random early drop can be enabled by specifying the three colon separated values "start:rate:full" (e.g. "10:30:60"). sshd(8) will refuse connection attempts with a probability of "rate/100" (30%) if there are currently "start" (10) unauthenticated connections. The probability increases linearly and all connection attempts are refused if the number of unauthenticated connections reaches "full" (60).'
      },
      'PasswordAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether password authentication is allowed.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'PermitEmptyPasswords',
      {
        'value_type' => 'enum',
        'help' => {
          'yes' => 'So, you want your machine to be part of a botnet ? ;-)'
        },
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'When password authentication is allowed, it specifies whether the server allows login to accounts with empty password strings.  The default is "no".',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'PermitOpen',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies the destinations to which TCP port forwarding is permitted. The forwarding specification must be one of the following forms: "host:port" or "IPv4_addr:port" or "[IPv6_addr]:port". An argument of "any" can be used to remove all restrictions and permit any forwarding requests. By default all port forwarding requests are permitted.'
      },
      'PermitRootLogin',
      {
        'value_type' => 'enum',
        'help' => {
          'forced-commands-only' => 'root login with public key authentication will be allowed, but only if the command option has been specified (which may be useful for taking remote backups even if root login is normally not allowed).  All other authentication methods are disabled for root.',
          'without-password' => 'password authentication is disabled for root',
          'no' => 'root is not allowed to log in
'
        },
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether root can log in using ssh(1).',
        'choice' => [
          'yes',
          'without-password',
          'forced-commands-only',
          'no'
        ]
      },
      'PermitTunnel',
      {
        'value_type' => 'enum',
        'help' => {
          'yes' => 'permits both "point-to-point" and "ethernet"'
        },
        'upstream_default' => 'no',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether tun(4) device forwarding is allowed. The argument must be "yes", "point-to-point" (layer 3), "ethernet" (layer 2), or "no".  Specifying "yes" permits both "point-to-point" and "ethernet".',
        'choice' => [
          'yes',
          'point-to-point',
          'ethernet',
          'no'
        ]
      },
      'PermitUserEnvironment',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether ~/.ssh/environment and environment= options in ~/.ssh/authorized_keys are processed by sshd(8). The default is "no". Enabling environment processing may enable users to bypass access restrictions in some configurations using mechanisms such as LD_PRELOAD.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'PidFile',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/var/run/sshd.pid',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies the file that contains the process ID of the SSH daemon.'
      },
      'PrintLastLog',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should print the date and time of the last user login when a user logs in interactively.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'PrintMotd',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should print /etc/motd when a user logs in interactively. (On some systems it is also printed by the shell, /etc/profile, or equivalent.)',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'Protocol',
      {
        'upstream_default_list' => [
          '1',
          '2'
        ],
        'type' => 'check_list',
        'description' => 'Specifies the protocol versions sshd(8) supports.  Note that the order of the protocol list does not indicate preference, because the client selects among multiple protocol versions offered by the server.',
        'choice' => [
          '1',
          '2'
        ]
      },
      'RhostsRSAAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether rhosts or /etc/hosts.equiv authentication together with successful RSA host authentication is allowed.  The default is "no". This option applies to protocol version 1 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'RSAAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether pure RSA authentication is allowed. This option applies to protocol version 1 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'ServerKeyBits',
      {
        'value_type' => 'integer',
        'min' => '512',
        'upstream_default' => '768',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Defines the number of bits in the ephemeral protocol version 1 server key. The minimum value is 512, and the default is 768.'
      },
      'PubkeyAuthentication',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Specifies whether public key authentication is allowed.  The default is "yes". Note that this option applies to protocol version 2 only.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'StrictModes',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should check file modes and ownership of the user\'s files and home directory before accepting login.  This is normally desirable because novices sometimes accidentally leave their directory or files world-writable.  The default is "yes".
',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'Subsystem',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'mandatory' => 1,
          'type' => 'leaf'
        },
        'experience' => 'advanced',
        'type' => 'hash',
        'description' => 'Configures an external subsystem (e.g. file transfer daemon). Keys of the hash should be a subsystem name and hash value a command (with optional arguments) to execute upon subsystem request. The command sftp-server(8) implements the "sftp" file transfer subsystem.  By default no subsystems are defined. Note that this option applies to protocol version 2 only.',
        'index_type' => 'string'
      },
      'SyslogFacility',
      {
        'value_type' => 'enum',
        'upstream_default' => 'AUTH',
        'type' => 'leaf',
        'description' => 'Gives the facility code that is used when logging messages from sshd(8). The default is AUTH.',
        'choice' => [
          'DAEMON',
          'USER',
          'AUTH',
          'LOCAL0',
          'LOCAL1',
          'LOCAL2',
          'LOCAL3',
          'LOCAL4',
          'LOCAL5',
          'LOCAL6',
          'LOCAL7'
        ]
      },
      'KeepAlive',
      {
        'value_type' => 'enum',
        'status' => 'deprecated',
        'type' => 'leaf',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'TCPKeepAlive',
      {
        'value_type' => 'enum',
        'help' => {
          'yes' => 'Send TCP keepalive messages. The server will notice if the network goes down or the client host crashes. This avoids infinitely hanging sessions.',
          'no' => 'disable TCP keepalive messages'
        },
        'upstream_default' => 'yes',
        'migrate_from' => {
          'formula' => '$keep_alive',
          'variables' => {
            'keep_alive' => '- KeepAlive'
          }
        },
        'type' => 'leaf',
        'description' => 'Specifies whether the system should send TCP keepalive messages to the other side. If they are sent, death of the connection or crash of one of the machines will be properly noticed. However, this means that connections will die if the route is down temporarily, and some people find it annoying.  On the other hand, if TCP keepalives are not sent, sessions may hang indefinitely on the server, leaving "ghost" users and consuming server resources. This option was formerly called KeepAlive.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'UseDNS',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should look up the remote host name and check that the resolved host name for the remote IP address maps back to the very same IP address. The default is "yes"',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'UseLogin',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether login(1) is used for interactive login sessions.  The default is "no". Note that login(1) is never used for remote command execution.  Note also, that if this is enabled, X11Forwarding will be disabled because login(1) does not know how to handle xauth(1) cookies. If UsePrivilegeSeparation is specified, it will be disabled after authentication',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'UsePAM',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Enables the Pluggable Authentication Module interface. If set to "yes" this will enable PAM authentication using ChallengeResponseAuthentication and PasswordAuthentication in addition to PAM account and session module processing for all authentication types.

Because PAM challenge-response authentication usually serves an equivalent role to password authentication, you should disable either PasswordAuthentication or ChallengeResponseAuthentication.

If UsePAM is enabled, you will not be able to run sshd(8) as a non-root user.  The default is "no".',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'UsePrivilegeSeparation',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) separates privileges by creating an unprivileged child process to deal with incoming network traffic.  After successful authentication, another process will be created that has the privilege of the authenticated user. The goal of privilege separation is to prevent privilege escalation by containing any corruption within the unprivileged processes. The default is "yes".',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'XAuthLocation',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/usr/bin/X11/xauth',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies the full pathname of the xauth(1) program.'
      },
      'X11DisplayOffset',
      {
        'value_type' => 'integer',
        'upstream_default' => '10',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies the first display number available for sshd(8)\'s X11 forwarding. This prevents sshd from interfering with real X11 servers.'
      },
      'X11Forwarding',
      {
        'value_type' => 'enum',
        'level' => 'important',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether X11 forwarding is permitted. Note that disabling X11 forwarding does not prevent users from forwarding X11 traffic, as users can always install their own forwarders. X11 forwarding is automatically disabled if UseLogin is enabled.',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'X11UseLocalhost',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should bind the X11 forwarding server to the loopback address or to the wildcard address. By default, sshd binds the forwarding server to the loopback address and sets the hostname part of the DISPLAY environment variable to "localhost". This prevents remote hosts from connecting to the proxy display. However, some older X11 clients may not function with this configuration. X11UseLocalhost may be set to "no" to specify that the forwarding server should be bound to the wildcard address.',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'Match',
      {
        'cargo' => {
          'type' => 'node',
          'config_class_name' => 'Sshd::MatchBlock'
        },
        'experience' => 'advanced',
        'type' => 'list',
        'description' => 'Specifies a match block. The criteria User, Group Host and Address can contain patterns. When all these criteria are satisfied (i.e. all patterns match the incoming connection), the parameters set in the block element will override the general settings.'
      }
    ],
    'read_config' => [
      {
        'backend' => 'OpenSsh::Sshd',
        'config_dir' => '/etc/ssh'
      },
      {
        'save' => 'backup',
        'file' => 'sshd_config',
        'backend' => 'augeas',
        'sequential_lens' => [
          'HostKey',
          'Subsystem',
          'Match'
        ],
        'config_dir' => '/etc/ssh'
      }
    ]
  }
]
;

