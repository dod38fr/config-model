[
          {
            'name' => 'Sshd',
            'include' => [
                           'Sshd::MatchElement'
                         ],
            'element' => [
                           'AcceptEnv',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => "Specifies what environment variables sent by the client will be copied into the session\x{2019}s environ(7).
"
                           },
                           'AddressFamily',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'any',
                             'type' => 'leaf',
                             'description' => 'Specifies which address family should be used by sshd(8).
',
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
                             'type' => 'list',
                             'description' => 'Login is allowed only for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.
'
                           },
                           'AllowUsers',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'Login is allowed only for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.
'
                           },
                           'AuthorizedKeysFile',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.
'
                           },
                           'ChallengeResponseAuthentication',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether challenge-response authentication is allowed. All authentication styles from login.conf(5) are supported.
'
                           },
                           'Ciphers',
                           {
                             'type' => 'check_list',
                             'description' => 'Specifies the ciphers allowed for protocol version 2. By default, all ciphers are allowed.

',
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
                           'ClientAliveCheck',
                           {
                             'value_type' => 'boolean',
                             'default' => '0',
                             'type' => 'leaf',
                             'description' => 'Check if client is alive by sending client alive messages
'
                           },
                           'ClientAliveInterval',
                           {
                             'value_type' => 'integer',
                             'level' => 'hidden',
                             'min' => '1',
                             'warp' => {
                                         'follow' => {
                                                       'c_a_check' => '- ClientAliveCheck'
                                                     },
                                         'rules' => [
                                                      '$c_a_check == 1',
                                                      {
                                                        'level' => 'normal'
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           },
                           'Compression',
                           {
                             'value_type' => 'enum',
                             'built_in' => 'delayed',
                             'type' => 'leaf',
                             'description' => 'Specifies whether compression is allowed, or delayed until the user has authenticated successfully.
',
                             'choice' => [
                                           'yes',
                                           'delayed',
                                           'no'
                                         ]
                           },
                           'DenyGroup',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'This keyword can be followed by a list of group name patterns, separated by spaces.  Login is disallowed for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups.  The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.
'
                           },
                           'DenyUSers',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'This keyword can be followed by a list of user name patterns, separated by spaces.  Login is disallowed for user names that match one of
 the patterns. Only user names are valid; a numerical user ID is not recognized. By default, login is allowed for all users. If the pattern takes the form USER@HOST then USER and HOST are separately checked, restricting logins to particular users from particular hosts. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.
'
                           },
                           'GSSAPIKeyExchange',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => "Specifies whether key exchange based on GSSAPI is allowed. GSSAPI key exchange doesn\x{2019}t rely on ssh keys to verify host identity. Note that this option applies to protocol version 2 only.

"
                           },
                           'GSSAPICleanupCredentials',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => "Specifies whether to automatically destroy the user\x{2019}s credentials cache on logout. Note that this option applies to protocol version 2 only.


"
                           },
                           'GSSAPIStrictAcceptorCheck',
                           {
                             'value_type' => 'boolean',
                             'help' => {
                                         '1' => 'the client must authenticate against the host service on the current hostname.
',
                                         '0' => "the client may authenticate against any service key stored in the machine\x{2019}s default store
"
                                       },
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => "Determines whether to be strict about the identity of the GSSAPI acceptor a client authenticates against.This facility is provided to assist with operation on multi homed machines. Note that this option applies only to protocol version 2 GSSAPI connections, and setting it to \x{201c}no\x{201d} may only work with recent Kerberos GSSAPI libraries.
"
                           },
                           'HostbasedAuthentication',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether rhosts or /etc/hosts.equiv authentication together with successful public key client host authentication is allowed (host-based authentication). This option is similar to RhostsRSAAuthentication and applies to protocol version 2 only.
'
                           },
                           'HostbasedUsesNameFromPacketOnly',
                           {
                             'value_type' => 'boolean',
                             'help' => {
                                         '1' => 'sshd(8) uses the name supplied by the client
',
                                         '0' => 'sshd(8) attempts to resolve the name from the TCP connection itself.
'
                                       },
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether or not the server will attempt to perform a reverse name lookup when matching the name in the ~/.shosts, ~/.rhosts, and /etc/hosts.equiv files during HostbasedAuthentication.
'
                           },
                           'HostKey',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => "Specifies a file containing a private host key used by SSH. The default is /etc/ssh/ssh_host_key for protocol version 1, and /etc/ssh/ssh_host_rsa_key and /etc/ssh/ssh_host_dsa_key for protocol version 2. Note that sshd(8) will refuse to use a file if it is group/world-accessible.  It is possible to have multiple host key files. \x{201c}rsa1\x{201d} keys are used for version 1 and \x{201c}dsa\x{201d} or \x{201c}rsa\x{201d} are used for version 2 of the SSH protocol.

"
                           },
                           'IgnoreRhosts',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies that .rhosts and .shosts files will not be used in RhostsRSAAuthentication or HostbasedAuthentication. /etc/hosts.equiv and /etc/ssh/shosts.equiv are still used. 
'
                           },
                           'IgnoreUserKnownHosts',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => "Specifies whether sshd(8) should ignore the user\x{2019}s ~/.ssh/known_hosts during RhostsRSAAuthentication or HostbasedAuthentication.
"
                           },
                           'KerberosGetAFSToken',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => "If AFS is active and the user has a Kerberos 5 TGT, attempt to acquire an AFS token before accessing the user\x{2019}s home directory.
"
                           },
                           'KerberosOrLocalPasswd',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'If password authentication through Kerberos fails then the password will be validated via any additional local mechanism such as /etc/passwd. 
'
                           },
                           'KerberosTicketCleanup',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => "Specifies whether to automatically destroy the user\x{2019}s ticket cache file on logout.
"
                           },
                           'KeyRegenerationInterval',
                           {
                             'value_type' => 'integer',
                             'built_in' => '3600',
                             'type' => 'leaf',
                             'description' => 'In protocol version 1, the ephemeral server key is automatically regenerated after this many seconds (if it has been used). The purpose
of regeneration is to prevent decrypting captured sessions by later breaking into the machine and stealing the keys. The key is never stored anywhere.  If the value is 0, the key is never regenerated. The default is 3600 (seconds).
'
                           },
                           'Port',
                           {
                             'value_type' => 'integer',
                             'built_in' => '22',
                             'type' => 'leaf'
                           },
                           'ListenAddress',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'Specifies the local addresses sshd(8) should listen on. The following forms may be used:

  host|IPv4_addr|IPv6_addr
  host|IPv4_addr:port
  [host|IPv6_addr]:port

If port is not specified, sshd will listen on the address and all prior Port options specified. The default is to listen on all local addresses.  Multiple ListenAddress options are permitted. Additionally, any Port options must precede this option for non-port qualified addresses.
'
                           },
                           'LoginGraceTime',
                           {
                             'value_type' => 'integer',
                             'built_in' => '120',
                             'type' => 'leaf',
                             'description' => 'The server disconnects after this time if the user has not successfully logged in.  If the value is 0, there is no time limit. The default is 120 seconds.
'
                           },
                           'LogLevel',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'DEBUG' => 'Logging with this level violates the privacy of users and is not recommended
',
                                         'DEBUG1' => 'Logging with this level violates the privacy of users and is not recommended
',
                                         'DEBUG3' => 'Logging with this level violates the privacy of users and is not recommended
',
                                         'DEBUG2' => 'Logging with this level violates the privacy of users and is not recommended
'
                                       },
                             'built_in' => 'INFO',
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
                                           'DEBUG3.'
                                         ]
                           },
                           'MACs',
                           {
                             'default_list' => [
                                                 'hmac-md5',
                                                 'hmac-md5-96',
                                                 'hmac-ripemd160',
                                                 'hmac-sha1',
                                                 'hmac-sha1-96',
                                                 'umac-64@openssh.com'
                                               ],
                             'type' => 'check_list',
                             'choice' => [
                                           'hmac-md5',
                                           'hmac-sha1',
                                           'umac-64@openssh.com',
                                           'hmac-ripemd160',
                                           'hmac-sha1-96',
                                           'hmac-md5-96'
                                         ]
                           },
                           'Match',
                           {
                             'type' => 'node',
                             'config_class_name' => 'Sshd::MatchBlock'
                           },
                           'MaxAuthTries',
                           {
                             'value_type' => 'integer',
                             'built_in' => '6',
                             'type' => 'leaf',
                             'description' => 'Specifies the maximum number of authentication attempts permitted per connection. Once the number of failures reaches half this value, additional failures are logged.
'
                           },
                           'MaxStartups',
                           {
                             'value_type' => 'uniline',
                             'built_in' => '10',
                             'type' => 'leaf',
                             'description' => "Specifies the maximum number of concurrent unauthenticated connections to the SSH daemon.  Additional connections will be dropped until
authentication succeeds or the LoginGraceTime expires for a connection.  The default is 10.

Alternatively, random early drop can be enabled by specifying the three colon separated values \x{201c}start:rate:full\x{201d} (e.g. \"10:30:60\"). sshd(8) will refuse connection attempts with a probability of \x{201c}rate/100\x{201d} (30%) if there are currently \x{201c}start\x{201d} (10) unauthenticated connections.  The probability increases linearly and all connection attempts are refused if the number of unauthenticated connections reaches \x{201c}full\x{201d} (60).
"
                           },
                           'PermitEmptyPasswords',
                           {
                             'value_type' => 'boolean',
                             'help' => {
                                         '1' => 'So, you want your machine to be part of a botnet ? ;-)
'
                                       },
                             'built_in' => '0',
                             'type' => 'leaf'
                           },
                           'PermitRootLogin',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         'forced-commands-only' => 'root login with public key authentication will be allowed, but only if the command option has been specified (which may be useful for taking remote backups even if root login is normally not allowed).  All other authentication methods are disabled for root.
',
                                         'without-password' => 'password authentication is disabled for root
',
                                         'no' => 'root is not allowed to log in
'
                                       },
                             'built_in' => 'yes',
                             'type' => 'leaf',
                             'description' => 'Specifies whether root can log in using ssh(1).
',
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
                                         'yes' => "permits both \x{201c}point-to-point\x{201d} and \x{201c}ethernet\x{201d}
"
                                       },
                             'built_in' => 'no',
                             'type' => 'leaf',
                             'description' => "Specifies whether tun(4) device forwarding is allowed. The argument must be \x{201c}yes\x{201d}, \x{201c}point-to-point\x{201d} (layer 3), \x{201c}ethernet\x{201d} (layer 2), or
 \x{201c}no\x{201d}.  Specifying \x{201c}yes\x{201d} permits both \x{201c}point-to-point\x{201d} and \x{201c}ethernet\x{201d}.
",
                             'choice' => [
                                           'yes',
                                           'point-to-point',
                                           'ethernet',
                                           'no'
                                         ]
                           },
                           'PermitUserEnvironment',
                           {
                             'value_type' => 'boolean',
                             'built_in' => 'no',
                             'type' => 'leaf',
                             'description' => "Specifies whether ~/.ssh/environment and environment= options in ~/.ssh/authorized_keys are processed by sshd(8). The default is \x{201c}no\x{201d}. Enabling environment processing may enable users to bypass access restrictions in some configurations using mechanisms such as LD_PRELOAD.
"
                           },
                           'PidFile',
                           {
                             'value_type' => 'uniline',
                             'built_in' => '/var/run/sshd.pid',
                             'type' => 'leaf',
                             'description' => 'Specifies the file that contains the process ID of the SSH daemon.
'
                           },
                           'PrintLastLog',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether sshd(8) should print the date and time of the last user login when a user logs in interactively.
'
                           },
                           'PrintMotd',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether sshd(8) should print /etc/motd when a user logs in interactively.  (On some systems it is also printed by the shell,   /etc/profile, or equivalent.) 
'
                           },
                           'Protocol',
                           {
                             'default_list' => [
                                                 '1',
                                                 '2'
                                               ],
                             'type' => 'check_list',
                             'description' => 'Specifies the protocol versions sshd(8) supports.  Note that the order of the protocol list does not indicate preference, because the client selects among multiple protocol versions offered by the server.
',
                             'choice' => [
                                           '1',
                                           '2'
                                         ]
                           }
                         ]
          }
        ]
;
