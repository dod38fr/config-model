[
          {
            'name' => 'Sshd::MatchElement',
            'description' => [
                               'GatewayPorts',
                               'Specifies whether remote hosts are allowed to connect to ports forwarded for the client.  By default, sshd(8) binds remote port forwardings to the loopback address.  This prevents other remote hosts from connecting to forwarded ports.  GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.
'
                             ],
            'element' => [
                           'AllowTcpForwarding',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '1',
                             'type' => 'leaf'
                           },
                           'Banner',
                           {
                             'value_type' => 'string',
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
                           }
                         ]
          }
        ]
;
