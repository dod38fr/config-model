[
          {
            'name' => 'Ssh::HostElement',
            'element' => [
                           'AddressFamily',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'any',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies which address family to use when connecting.',
                             'choice' => [
                                           'any',
                                           'inet',
                                           'inet6'
                                         ]
                           },
                           'BatchMode',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => "If set to \x{201c}yes\x{201d}, passphrase/password querying will be disabled. In addition, the ServerAliveInterval option will be set to 300 seconds by default. This option is useful in scripts and other batch jobs where no user is present to supply the password, and where it is desirable to detect a broken network swiftly. "
                           },
                           'BindAddress',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => "Use the specified address on the local machine as the source address of the connection. Only useful on systems with more than one address. Note that this option does not work if UsePrivilegedPort is set to \x{201c}yes\x{201d}."
                           },
                           'ChallengeResponseAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to use challenge-response authentication.'
                           },
                           'CheckHostIP',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'type' => 'leaf',
                             'description' => 'If enabled, ssh(1) will additionally check the host IP address in the known_hosts file. This allows ssh to detect if a host key changed due to DNS spoofing. If disbled, the check will not be executed.'
                           },
                           'Cipher',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => '3des',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the cipher to use for encrypting the session in protocol version 1. "des" is only supported in the ssh(1) client for interoperability with legacy protocol 1 implementations that do not support the 3des cipher. Its use is strongly discouraged due to cryptographic weaknesses.',
                             'choice' => [
                                           'blowfish',
                                           '3des',
                                           'des'
                                         ]
                           },
                           'Ciphers',
                           {
                             'ordered' => '1',
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
                             'description' => 'Specifies the ciphers allowed for protocol version 2 in order of preference. By default, all ciphers are allowed.',
                             'choice' => [
                                           'aes128-cbc',
                                           '3des-cbc',
                                           'blowfish-cbc',
                                           'cast128-cbc',
                                           'arcfour128',
                                           'arcfour256',
                                           'arcfour',
                                           'aes192-cbc',
                                           'aes256-cbc',
                                           'aes128-ctr',
                                           'aes192-ctr',
                                           'aes256-ctr'
                                         ]
                           },
                           'ClearAllForwardings',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies that all local, remote, and dynamic port forwardings specified in the configuration files or on the command line be cleared. This option is primarily useful when used from the ssh(1) command line to clear port forwardings set in configuration files, and is automatically set by scp(1) and sftp(1).'
                           },
                           'Compression',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to use compression.'
                           },
                           'CompressionLevel',
                           {
                             'min' => '1',
                             'upstream_default' => '6',
                             'max' => '9',
                             'experience' => 'advanced',
                             'value_type' => 'integer',
                             'level' => 'hidden',
                             'warp' => {
                                         'follow' => {
                                                       'compression' => '- Compression'
                                                     },
                                         'rules' => [
                                                      '$compression == 1',
                                                      {
                                                        'level' => 'normal'
                                                      }
                                                    ]
                                       },
                             'type' => 'leaf'
                           },
                           'ConnectionAttempts',
                           {
                             'value_type' => 'integer',
                             'min' => '1',
                             'upstream_default' => '1',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the number of tries (one per second) to make before exiting. The argument must be an integer. This may be useful in scripts if the connection sometimes fails.'
                           },
                           'ConnectTimeout',
                           {
                             'value_type' => 'integer',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the timeout (in seconds) used when connecting to the SSH server, instead of using the default system TCP timeout. This value is used only when the target is down or really unreachable, not when it refuses the connection.
'
                           },
                           'ControlMaster',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'no',
                             'experience' => 'master',
                             'type' => 'leaf',
                             'description' => 'Enables the sharing of multiple sessions over a single network connection. When set to ``yes\'\', ssh(1) will listen for connections on a control socket specified using the ControlPath argument. Additional sessions can connect to this socket using the same ControlPath with ControlMaster set to ``no\'\' (the default). These sessions will try to reuse the master instance\'s network connection rather than initiating new ones, but will fall back to connecting normally if the control socket does not exist, or is not listening.

Setting this to ``ask\'\' will cause ssh to listen for control connections, but require confirmation using the SSH_ASKPASS program before they are accepted (see ssh-add(1) for details). If the ControlPath cannot be opened, ssh will continue without connecting to a master instance.

X11 and ssh-agent(1) forwarding is supported over these multiplexed connections, however the display and agent forwarded will be the one belonging to the master connection i.e. it is not pos sible to forward multiple displays or agents.

Two additional options allow for opportunistic multiplexing: try to use a master connection but fall back to creating a new one if
 one does not already exist. These options are: ``auto\'\' and ``autoask\'\'. The latter requires confirmation like the ``ask\'\' option.
',
                             'choice' => [
                                           'no',
                                           'yes',
                                           'ask',
                                           'autoask'
                                         ]
                           },
                           'ControlPath',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'master',
                             'type' => 'leaf',
                             'description' => 'Specify the path to the control socket used for connection sharing as described in the ControlMaster section above or the string ``none\'\' to disable connection sharing.  In the path, `%l\' will be substituted by the local host name, `%h\' will be substituted by the target host name, `%p\' the port, and `%r\' by the remotelogin username. It is recommended that any ControlPath used for opportunistic connection sharing include at least %h, %p, and %r. This ensures that shared connections are uniquely identified.
'
                           },
                           'DynamicForward',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Specifies that a TCP port on the local machine be forwarded over the secure channel, and the application protocol is then used to determine where to connect to from the remote machine.

The argument must be [bind_address:]port. IPv6 addresses can be specified by enclosing addresses in square brackets or by using an alternative syntax: [bind_address/]port. By default, the local port is bound in accordance with the GatewayPorts setting. However, an explicit bind_address may be used to bind the connection to a specific address. The bind_address of ``localhost\'\' indicates that the listening port be bound for local use only, while an empty address or `*\' indicates that the port should be available from all interfaces.

Currently the SOCKS4 and SOCKS5 protocols are supported, and ssh(1) will act as a SOCKS server. Multiple forwardings may be specified, and additional forwardings can be given on the command line. Only the superuser can forward privileged ports.
'
                           },
                           'EscapeChar',
                           {
                             'value_type' => 'uniline',
                             'upstream_default' => '~',
                             'type' => 'leaf',
                             'description' => 'Sets the escape character (default: `~\'). The escape character can also be set on the command line.  The argument should be a single character, `^\' followed by a letter, or ``none\'\' to disable the escape character entirely (making the connection transparent for binary data).
'
                           },
                           'ExitOnForwardFailure',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether ssh(1) should terminate the connection if it cannot set up all requested dynamic, tunnel, local, and remote port forwardings.'
                           },
                           'ForwardAgent',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether the connection to the authentication agent (if any) will be forwarded to the remote machine. 

Agent forwarding should be enabled with caution.  Users with the ability to bypass file permissions on the remote host (for the agent\'s Unix-domain socket) can access the local agent through the forwarded connection.  An attacker cannot obtain key material from the agent, however they can perform operations on the keys that enable them to authenticate using the identities loaded into the agent.
'
                           },
                           'ForwardX11',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether X11 connections will be automatically redirected over the secure channel and DISPLAY set.

X11 forwarding should be enabled with caution.  Users with the ability to bypass file permissions on the remote host (for the user\'s X11 authorization database) can access the local X11 dis play through the forwarded connection.  An attacker may then be able to perform activities such as keystroke monitoring if the ForwardX11Trusted option is also enabled.
'
                           },
                           'ForwardX11Trusted',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'If this option is set, remote X11 clients will have full access to the original X11 display.

If this option is not set, remote X11 clients will be considered untrusted and prevented from stealing or tampering with data belonging to trusted X11 clients. Furthermore, the xauth(1) token used for the session will be set to expire after 20 minutes. Remote clients will be refused access after this time.

See the X11 SECURITY extension specification for full details on the restrictions imposed on untrusted clients.
'
                           },
                           'GatewayPorts',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether remote hosts are allowed to connect to local forwarded ports. By default, ssh(1) binds local port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that ssh should bind local port forwardings to the wildcard address, thus allowing remote hosts to connect to forwarded ports. '
                           },
                           'GlobalKnownHostsFile',
                           {
                             'value_type' => 'uniline',
                             'upstream_default' => '/etc/ssh/ssh_known_hosts',
                             'type' => 'leaf',
                             'description' => 'Specifies a file to use for the global host key database'
                           },
                           'GSSAPIAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'master',
                             'type' => 'leaf',
                             'description' => 'Specifies whether user authentication based on GSSAPI is allowed. Note that this option applies to protocol version 2 only.'
                           },
                           'GSSAPIDelegateCredentials',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'master',
                             'type' => 'leaf',
                             'description' => 'Forward (delegate) credentials to the server. Note that this option applies to protocol version 2 only.
'
                           },
                           'HashKnownHosts',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Indicates that ssh(1) should hash host names and addresses when they are added to ~/.ssh/known_hosts. These hashed names may be used normally by ssh(1) and sshd(8), but they do not reveal identifying information should the file\'s contents be disclosed. Note that existing names and addresses in known hosts files will not be converted automatically, but may be manually hashed using ssh-keygen(1).
'
                           },
                           'HostbasedAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to try rhosts based authentication with public key authentication. This option applies to protocol version 2 only and is similar to RhostsRSAAuthentication.
'
                           },
                           'HostKeyAlgorithms',
                           {
                             'ordered' => '1',
                             'experience' => 'master',
                             'upstream_default_list' => [
                                                          'ssh-rsa',
                                                          'ssh-dss'
                                                        ],
                             'type' => 'check_list',
                             'description' => 'Specifies the protocol version 2 host key algorithms that the client wants to use in order of preference.',
                             'choice' => [
                                           'ssh-rsa',
                                           'ssh-dss'
                                         ]
                           },
                           'HostKeyAlias',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies an alias that should be used instead of the real host name when looking up or saving the host key in the host key database files. This option is useful for tunneling SSH connections or for multiple servers running on a single host.'
                           },
                           'HostName',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the real host name to log into. This can be used to specify nicknames or abbreviations for hosts. The default is the name given on the command line. Numeric IP addresses are also permitted (both on the command line and in HostName specifications).'
                           },
                           'IdentitiesOnly',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies that ssh(1) should only use the authentication identity files configured in the ssh_config files, even if ssh-agent(1) offers more identities. This option is intended for situations where ssh-agent offers many different identities.'
                           },
                           'IdentityFile',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'experience' => 'advanced',
                             'type' => 'list',
                             'description' => 'Specifies a file from which the user\'s RSA or DSA authentication identity is read. The default is ~/.ssh/identity for protocol version 1, and ~/.ssh/id_rsa and ~/.ssh/id_dsa for protocol version 2. Additionally, any identities represented by the authentication agent will be used for authentication.

The file name may use the tilde syntax to refer to a user\'s home directory or one of the following escape characters: `%d\' (local user\'s home directory), `%u\' (local user name), `%l\' (local host  name), `%h\' (remote host name) or `%r\' (remote user name).

It is possible to have multiple identity files specified in con figuration files; all these identities will be tried in sequence.
'
                           },
                           'KbdInteractiveAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to use keyboard-interactive authentication.
'
                           },
                           'KbdInteractiveDevices',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'experience' => 'master',
                             'type' => 'list',
                             'description' => 'Specifies the list of methods to use in keyboard-interactive authentication.  Multiple method names must be comma-separated. The default is to use the server specified list. The methods available vary depending on what the server supports. For an OpenSSH server, it may be zero or more of: ``bsdauth\'\', ``pam\'\', and ``skey\'\'.'
                           },
                           'LocalForward',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies that a TCP port on the local machine be forwarded over the secure channel to the specified host and port from the remote machine. The first argument must be [bind_address:]port and the second argument must be host:hostport. IPv6 addresses can be specified by enclosing addresses in square brackets or by using an alternative syntax: [bind_address/]port and host/hostport. Multiple forwardings may be specified, and additional forwardings can be given on the command line. Only the superuser can forward privileged ports. By default, the local port is bound in accordance with the GatewayPorts setting.  However, an explicit bind_address may be used to bind the connection to a specific address.  The bind_address of "localhost" indicates that the listening port be bound for local use only, while an empty address or \'*\' indicates that the port should be available from all interfaces.'
                           },
                           'LogLevel',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'INFO',
                             'type' => 'leaf',
                             'description' => 'Gives the verbosity level that is used when logging messages from ssh(1).  The possible values are: SILENT, QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG, DEBUG1, DEBUG2, and DEBUG3.  The default is INFO.  DEBUG and DEBUG1 are equivalent.  DEBUG2 and DEBUG3 each specify higher levels of verbose output.',
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
                             'ordered' => '1',
                             'experience' => 'master',
                             'upstream_default_list' => [
                                                          'hmac-md5',
                                                          'hmac-sha1',
                                                          'umac-64@openssh.com',
                                                          'hmac-ripemd160',
                                                          'hmac-sha1-96',
                                                          'hmac-md5-96'
                                                        ],
                             'type' => 'check_list',
                             'description' => 'Specifies the MAC (message authentication code) algorithms in order of preference. The MAC algorithm is used in protocol version 2 for data integrity protection.',
                             'choice' => [
                                           'hmac-md5',
                                           'hmac-sha1',
                                           'umac-64@openssh.com',
                                           'hmac-ripemd160',
                                           'hmac-sha1-96',
                                           'hmac-md5-96'
                                         ]
                           },
                           'NoHostAuthenticationForLocalhost',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'This option can be used if the home directory is shared across machines. In this case localhost will refer to a different machine on each of the machines and the user will get many warn ings about changed host keys. However, this option disables host authentication for localhost. The default is to check the host key for localhost.'
                           },
                           'NumberOfPasswordPrompts',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '3',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the number of password prompts before giving up.'
                           },
                           'PasswordAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to use password authentication.'
                           },
                           'PermitLocalCommand',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Allow local command execution via the LocalCommand option or using the !command escape sequence in ssh(1).'
                           },
                           'LocalCommand',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies a command to execute on the local machine after successfully connecting to the server. The command string extends to the end of the line, and is executed with the user\'s shell. The following escape character substitutions will be performed: \'%d\' (local user\'s home directory), \'%h\' (remote host name), \'%l\' (local host name), \'%n\' (host name as provided on the command line), \'%p\' (remote port), \'%r\' (remote user name) or \'%u\' (local user name). This directive is ignored unless PermitLocalCommand has been enabled.'
                           },
                           'Port',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '22',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the port number to connect on the remote host.'
                           },
                           'PreferredAuthentications',
                           {
                             'ordered' => '1',
                             'experience' => 'advanced',
                             'upstream_default_list' => [
                                                          'gssapi-with-mic',
                                                          'hostbased',
                                                          'publickey',
                                                          'keyboard-interactive',
                                                          'password'
                                                        ],
                             'type' => 'check_list',
                             'description' => 'Specifies the order in which the client should try protocol 2 authentication methods.  This allows a client to prefer one method (e.g. keyboard-interactive) over another method (e.g. password).',
                             'choice' => [
                                           'gssapi-with-mic',
                                           'hostbased',
                                           'publickey',
                                           'keyboard-interactive',
                                           'password'
                                         ]
                           },
                           'Protocol',
                           {
                             'ordered' => '1',
                             'upstream_default_list' => [
                                                          '2',
                                                          '1'
                                                        ],
                             'type' => 'check_list',
                             'description' => 'Specifies the protocol versions ssh(1) should support in order of preference.  The default is "2,1".  This means that ssh tries version 2 and falls back to version 1 if version 2 is not available.',
                             'choice' => [
                                           '2',
                                           '1'
                                         ]
                           },
                           'ProxyCommand',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the command to use to connect to the server. The command string extends to the end of the line, and is executed with the user\'s shell. In the command string, \'%h\' will be substi tuted by the host name to connect and \'%p\' by the port.  The com mand can be basically anything, and should read from its standard input and write to its standard output. It should eventually connect an sshd(8) server running on some machine, or execute sshd -i somewhere. Host key management will be done using the HostName of the host being connected (defaulting to the name typed by the user).  Setting the command to "none" disables this option entirely. Note that CheckHostIP is not available for connects with a proxy command.

This directive is useful in conjunction with nc(1) and its proxy support. For example, the following directive would connect via an HTTP proxy at 192.0.2.0:

    ProxyCommand /usr/bin/nc -X connect -x 192.0.2.0:8080 %h %p'
                           },
                           'PubkeyAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to try public key authentication. This option applies to protocol version 2 only.'
                           },
                           'RekeyLimit',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the maximum amount of data that may be transmitted before the session key is renegotiated.  The argument is the number of bytes, with an optional suffix of \'K\', \'M\', or \'G\' to indicate Kilobytes, Megabytes, or Gigabytes, respectively.  The default is between \'1G\' and \'4G\', depending on the cipher.  This option applies to protocol version 2 only.'
                           },
                           'RemoteForward',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Specifies that a TCP port on the remote machine be forwarded over the secure channel to the specified host and port from the local machine.  The first argument must be [bind_address:]port and the second argument must be host:hostport.  IPv6 addresses can be specified by enclosing addresses in square brackets or by using an alternative syntax: [bind_address/]port and host/hostport. Multiple forwardings may be specified, and additional forwardings can be given on the command line.  Only the superuser can forward privileged ports.

If the bind_address is not specified, the default is to only bind to loopback addresses.  If the bind_address is \'*\' or an empty string, then the forwarding is requested to listen on all inter faces.  Specifying a remote bind_address will only succeed if the server\'s GatewayPorts option is enabled (see sshd_config(5)).'
                           },
                           'RhostsRSAAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to try rhosts based authentication with RSA host authentication. This option applies to protocol version 1 only and requires ssh(1) to be setuid root.'
                           },
                           'RSAAuthentication',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to try RSA authentication. RSA authentication will only be attempted if the identity file exists, or an authentication agent is running. Note that this option applies to protocol version 1 only.'
                           },
                           'SendEnv',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'Specifies what variables from the local environ(7) should be sent to the server. Note that environment passing is only supported for protocol 2. The server must also support it, and the server must be configured to accept these environment variables. Refer to AcceptEnv in sshd_config(5) for how to configure the server. Variables are specified by name, which may contain wildcard char acters. Multiple environment variables may be separated by whitespace or spread across multiple SendEnv directives. The default is not to send any environment variables.

See PATTERNS in ssh_config(5) for more information on patterns.'
                           },
                           'ServerAliveCountMax',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => '3',
                             'type' => 'leaf',
                             'description' => 'Sets the number of server alive messages (see below) which may be sent without ssh(1) receiving any messages back from the server. If this threshold is reached while server alive messages are being sent, ssh will disconnect from the server, terminating the session.  It is important to note that the use of server alive messages is very different from TCPKeepAlive.  The server alive messages are sent through the encrypted channel and there fore will not be spoofable. The TCP keepalive option enabled by TCPKeepAlive is spoofable. The server alive mechanism is valuable when the client or server depend on knowing when a connec tion has become inactive.

The default value is 3. If, for example, ServerAliveInterval is set to 15 and ServerAliveCountMax is left at the default, if the server becomes unresponsive, ssh will disconnect after approximately 45 seconds.  This option applies to protocol version 2 only; in protocol version 1 there is no mechanism to request a response from the server to the server alive messages, so disconnection is the responsibility of the TCP stack.'
                           },
                           'ServerAliveInterval',
                           {
                             'value_type' => 'boolean',
                             'warp' => {
                                         'follow' => {
                                                       'batch_mode' => '?BatchMode'
                                                     },
                                         'rules' => [
                                                      '$batch_mode eq \'1\'',
                                                      {
                                                        'upstream_default' => '300'
                                                      }
                                                    ]
                                       },
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Sets a timeout interval in seconds after which if no data has been received from the server, ssh(1) will send a message through the encrypted channel to request a response from the server.  The default is 0, indicating that these messages will not be sent to the server, or 300 if the BatchMode option is set.  This option applies to protocol version 2 only.  ProtocolKeepAlives and SetupTimeOut are Debian-specific compatibility aliases for this option.'
                           },
                           'SmartcardDevice',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies which smartcard device to use.  The argument to this keyword is the device ssh(1) should use to communicate with a smartcard used for storing the user\'s private RSA key.  By default, no device is specified and smartcard support is not activated.'
                           },
                           'StrictHostKeyChecking',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'ask',
                             'type' => 'leaf',
                             'description' => 'If this flag is set to "yes", ssh(1) will never automatically add host keys to the ~/.ssh/known_hosts file, and refuses to connect to hosts whose host key has changed.  This provides maximum protection against trojan horse attacks, though it can be annoying when the /etc/ssh/ssh_known_hosts file is poorly maintained or when connections to new hosts are frequently made.  This option forces the user to manually add all new hosts.  If this flag is set to "no", ssh will automatically add new host keys to the user known hosts files.  If this flag is set to "ask", new host keys will be added to the user known host files only after the user has confirmed that is what they really want to do, and ssh will refuse to connect to hosts whose host key has changed.  The host keys of known hosts will be verified automatically in all cases. The argument must be "yes", "no", or "ask".  The default is "ask".',
                             'choice' => [
                                           'yes',
                                           'no',
                                           'ask'
                                         ]
                           },
                           'TCPKeepAlive',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether the system should send TCP keepalive messages to the other side.  If they are sent, death of the connection or crash of one of the machines will be properly noticed.  This option only uses TCP keepalives (as opposed to using ssh level keepalives), so takes a long time to notice when the connection dies.  As such, you probably want the ServerAliveInterval option as well.  However, this means that connections will die if the route is down temporarily, and some people find it annoying. The default is "yes" (to send TCP keepalive messages), and the client will notice if the network goes down or the remote host dies.  This is important in scripts, and many users want it too.

To disable TCP keepalive messages, the value should be set to "no".'
                           },
                           'Tunnel',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'no',
                             'type' => 'leaf',
                             'description' => 'Request tun(4) device forwarding between the client and the server.  The argument must be "yes", "point-to-point" (layer 3), "ethernet" (layer 2), or "no".  Specifying "yes" requests the default tunnel mode, which is "point-to-point".  The default is "no".',
                             'choice' => [
                                           'yes',
                                           'point-to-point',
                                           'ethernet',
                                           'no'
                                         ]
                           },
                           'TunnelDevice',
                           {
                             'value_type' => 'uniline',
                             'upstream_default' => 'any:any',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies the tun(4) devices to open on the client (local_tun) and the server (remote_tun).

             The argument must be local_tun[:remote_tun].  The devices may be specified by numerical ID or the keyword "any", which uses the next available tunnel device.  If remote_tun is not specified, it defaults to "any".  The default is "any:any".'
                           },
                           'UseBlacklistedKeys',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether ssh(1) should use keys recorded in its blacklist of known-compromised keys (see ssh-vulnkey(1)) for authentication.  If "yes", then attempts to use compromised keys for authentication will be logged but accepted.  It is strongly recommended that this be used only to install new authorized keys on the remote system, and even then only with the utmost care.  If "no", then attempts to use compromised keys for authentication will be prevented.  The default is "no".'
                           },
                           'UsePrivilegedPort',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to use a privileged port for outgoing connections.  The argument must be "yes" or "no".  The default is "no". If set to "yes", ssh(1) must be setuid root.  Note that this option must be set to "yes" for RhostsRSAAuthentication with older servers.'
                           },
                           'User',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Specifies the user to log in as.  This can be useful when a dif ferent user name is used on different machines.  This saves the trouble of having to remember to give the user name on the command line.'
                           },
                           'UserKnownHostsFile',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Specifies a file to use for the user host key database instead of ~/.ssh/known_hosts.'
                           },
                           'VerifyHostKeyDNS',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'no',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to verify the remote key using DNS and SSHFP resource records.  If this option is set to "yes", the client will implicitly trust keys that match a secure fingerprint from DNS.  Insecure fingerprints will be handled as if this option was set to "ask".  If this option is set to "ask", information on fingerprint match will be displayed, but the user will still need to confirm new host keys according to the StrictHostKeyChecking option.  The argument must be "yes", "no", or "ask".  The default is "no".  Note that this option applies to protocol version 2 only. 
See also VERIFYING HOST KEYS in ssh(1).',
                             'choice' => [
                                           'yes',
                                           'no',
                                           'ask'
                                         ]
                           },
                           'VisualHostKey',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'If this flag is set to "yes", an ASCII art representation of the remote host key fingerprint is printed additionally to the hex fingerprint string.  If this flag is set to "no", only the hex fingerprint string will be printed.  The default is "no".'
                           },
                           'XAuthLocation',
                           {
                             'value_type' => 'uniline',
                             'upstream_default' => '/usr/X11R6/bin/xauth',
                             'type' => 'leaf',
                             'description' => 'Specifies the full pathname of the xauth(1) program.  The default is /usr/bin/X11/xauth.'
                           }
                         ]
          }
        ]
;
