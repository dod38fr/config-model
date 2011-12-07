[
  {
    'class_description' => 'Configuration class that represents the parameters required
to specify port forwarding in a ssh configuration.',
    'name' => 'Ssh::PortForward',
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'ipv6',
      {
        'value_type' => 'boolean',
        'type' => 'leaf',
        'description' => 'Specify if the forward is specified iwth IPv6 or IPv4'
      },
      'bind_address',
      {
        'value_type' => 'uniline',
        'summary' => 'bind address to listen to',
        'type' => 'leaf',
        'description' => "Specify the address that the port will listen to. By default, only connections coming from localhost (127.0.0.1) will be forwarded.

By default, the local port is bound in accordance with the GatewayPorts setting. However, an explicit bind_address may be used to bind the connection to a specific address.

The bind_address of \x{201c}localhost\x{201d} indicates that the listening port be bound for local use only, while an empty address or \x{2018}*\x{2019} indicates that the port should be available from all interfaces."
      },
      'port',
      {
        'value_type' => 'uniline',
        'mandatory' => '1',
        'type' => 'leaf',
        'description' => 'Listening port. Connection made to this port will be forwarded to the other side of the tunnel.'
      },
      'host',
      {
        'value_type' => 'uniline',
        'summary' => 'host name or address',
        'mandatory' => '1',
        'type' => 'leaf'
      },
      'hostport',
      {
        'value_type' => 'uniline',
        'summary' => 'destination port',
        'mandatory' => '1',
        'type' => 'leaf',
        'description' => 'Port number to connect the tunnel to.'
      }
    ]
  }
]
;

