[
          {
            'name' => 'Sshd::MatchElement',
            'description' => [
                               'AllowTcpForwarding',
                               "Specifies whether TCP forwarding is permitted. The default is \x{201c}yes\x{201d}.Note that disabling TCP forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.
",
                               'ForceCommand',
                               "Forces the execution of the command specified by ForceCommand, ignoring any command supplied by the client. The command is invoked by using the user\x{2019}s login shell with the -c option. This applies to shell, command, or subsystem execution. It is most useful inside a Match block. The command originally supplied by the client is available in the SSH_ORIGINAL_COMMAND environment variable.

",
                               'GatewayPorts',
                               'Specifies whether remote hosts are allowed to connect to ports forwarded for the client.  By default, sshd(8) binds remote port forwardings to the loopback address.  This prevents other remote hosts from connecting to forwarded ports.  GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.
',
                               'ForceCommand',
                               "Forces the execution of the command specified by ForceCommand, ignoring any command supplied by the client. The command is invoked by using the user\x{2019}s login shell with the -c option. This applies to shell, command, or subsystem execution. It is most useful inside a Match block. The command originally supplied by the client is available in the SSH_ORIGINAL_COMMAND environment variable.

"
                             ],
            'element' => [
                           'AllowTcpForwarding',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf'
                           },
                           'ForceCommand',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'GatewayPorts',
                           {
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
                             'choice' => [
                                           'yes',
                                           'clientspecified',
                                           'no'
                                         ]
                           },
                           'ForceCommand',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           }
                         ]
          }
        ]
;
