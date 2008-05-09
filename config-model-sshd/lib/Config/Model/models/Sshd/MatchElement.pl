[
          {
            'name' => 'Sshd::MatchElement',
            'element' => [
                           'AllowTcpForwarding',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => "Specifies whether TCP forwarding is permitted. The default is \x{201c}yes\x{201d}.Note that disabling TCP forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.
"
                           },
                           'Banner',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'In some jurisdictions, sending a warning message before authentication may be relevant for getting legal protection. The contents of the specified file are sent to the remote user before authentication is allowed. This option is only available for protocol version 2. By default, no banner is displayed.
'
                           },
                           'ForceCommand',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => "Forces the execution of the command specified by ForceCommand, ignoring any command supplied by the client. The command is invoked by using the user\x{2019}s login shell with the -c option. This applies to shell, command, or subsystem execution. It is most useful inside a Match block. The command originally supplied by the client is available in the SSH_ORIGINAL_COMMAND environment variable.

"
                           },
                           'GatewayPorts',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'enum',
                             'help' => {
                                         'yes' => 'force remote port forwardings to bind to the wildcard address
',
                                         'clientspecified' => 'allow the client to select the address to which the forwarding is bound
',
                                         'no' => 'No port forwarding
'
                                       },
                             'built_in' => 'no',
                             'type' => 'leaf',
                             'description' => 'Specifies whether remote hosts are allowed to connect to ports forwarded for the client.  By default, sshd(8) binds remote port forwardings to the loopback address.  This prevents other remote hosts from connecting to forwarded ports.  GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.
',
                             'choice' => [
                                           'yes',
                                           'clientspecified',
                                           'no'
                                         ]
                           },
                           'GSSAPIAuthentication',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether user authentication based on GSSAPI is allowed. Note that this option applies to protocol version 2 only.
'
                           },
                           'KbdInteractiveAuthentication',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'No doc found in sshd documentation
'
                           },
                           'KerberosAuthentication',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf'
                           },
                           'PasswordAuthentication',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf'
                           },
                           'PermitOpen',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => "Specifies the destinations to which TCP port forwarding is permitted. The forwarding specification must be one of the following forms:
\"host:port\" or \"IPv4_addr:port\" or \"[IPv6_addr]:port\". An argument of \x{201c}any\x{201d} can be used to remove all restrictions and permit any forwarding requests. By default all port forwarding requests are permitted.

"
                           },
                           'RhostsRSAAuthentication',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => "Specifies whether rhosts or /etc/hosts.equiv authentication together with successful RSA host authentication is allowed.  The default is \x{201c}no\x{201d}. This option applies to protocol version 1 only.
"
                           },
                           'RSAAuthentication',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf',
                             'description' => 'Specifies whether pure RSA authentication is allowed. This option applies to protocol version 1 only.
'
                           },
                           'X11DisplayOffset',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'integer',
                             'built_in' => '10',
                             'type' => 'leaf',
                             'description' => "Specifies the first display number available for sshd(8)\x{2019}s X11 forwarding. This prevents sshd from interfering with real X11 servers.
"
                           },
                           'X11Forwarding',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'enum',
                             'built_in' => 'no',
                             'type' => 'leaf',
                             'description' => 'Specifies whether X11 forwarding is permitted. Note that disabling X11 forwarding does not prevent users from forwarding X11 traffic, as users can always install their own forwarders. X11 forwarding is automatically disabled if UseLogin is enabled.
',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'X11UseLocalhost',
                           {
                             'compute' => {
                                            'formula' => '$main',
                                            'variables' => {
                                                             'main' => '- - - &element'
                                                           },
                                            'allow_override' => '1'
                                          },
                             'value_type' => 'enum',
                             'built_in' => 'yes',
                             'type' => 'leaf',
                             'description' => "Specifies whether sshd(8) should bind the X11 forwarding server to the loopback address or to the wildcard address.  By default, sshd binds the forwarding server to the loopback address and sets the hostname part of the DISPLAY environment variable to \x{201c}localhost\x{201d}. This prevents remote hosts from connecting to the proxy display.  However, some older X11 clients may not function with this configuration. X11UseLocalhost may be set to \x{201c}no\x{201d} to specify that the forwarding server should be bound to the wildcard address.
",
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           }
                         ]
          }
        ]
;
