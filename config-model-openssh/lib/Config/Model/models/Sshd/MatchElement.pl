[
  {
    'class_description' => 'Configuration class that represents all parameters available 
inside a Match block of a sshd configuration.',
    'name' => 'Sshd::MatchElement',
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
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
        'value_type' => 'enum',
        'level' => 'important',
        'type' => 'leaf',
        'description' => 'Specifies whether TCP forwarding is permitted. The default is "yes".Note that disabling TCP forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.',
        'choice' => [
          'no',
          'yes'
        ]
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
        'description' => 'In some jurisdictions, sending a warning message before authentication may be relevant for getting legal protection. The contents of the specified file are sent to the remote user before authentication is allowed. This option is only available for protocol version 2. By default, no banner is displayed.'
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
        'description' => 'Forces the execution of the command specified by ForceCommand, ignoring any command supplied by the client. The command is invoked by using the user\'s login shell with the -c option. This applies to shell, command, or subsystem execution. It is most useful inside a Match block. The command originally supplied by the client is available in the SSH_ORIGINAL_COMMAND environment variable.'
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
          'yes' => 'force remote port forwardings to bind to the wildcard address',
          'clientspecified' => 'allow the client to select the address to which the forwarding is bound',
          'no' => 'No port forwarding'
        },
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether remote hosts are allowed to connect to ports forwarded for the client.  By default, sshd(8) binds remote port forwardings to the loopback address.  This prevents other remote hosts from connecting to forwarded ports.  GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.',
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
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether user authentication based on GSSAPI is allowed. Note that this option applies to protocol version 2 only.',
        'choice' => [
          'no',
          'yes'
        ]
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
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'No doc found in sshd documentation',
        'choice' => [
          'no',
          'yes'
        ]
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
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether the password provided by the user for PasswordAuthentication will be validated through the Kerberos KDC. To use this option, the server needs a Kerberos servtab which allows the verification of the KDC\'s identity. The default is "no".',
        'choice' => [
          'no',
          'yes'
        ]
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
        'value_type' => 'enum',
        'level' => 'important',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether password authentication is allowed.',
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
        'type' => 'list',
        'description' => 'Specifies the destinations to which TCP port forwarding is permitted. The forwarding specification must be one of the following forms: "host:port" or "IPv4_addr:port" or "[IPv6_addr]:port". An argument of "any" can be used to remove all restrictions and permit any forwarding requests. By default all port forwarding requests are permitted.'
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
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Specifies whether rhosts or /etc/hosts.equiv authentication together with successful RSA host authentication is allowed.  The default is "no". This option applies to protocol version 1 only.',
        'choice' => [
          'no',
          'yes'
        ]
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
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether pure RSA authentication is allowed. This option applies to protocol version 1 only.',
        'choice' => [
          'no',
          'yes'
        ]
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
        'upstream_default' => '10',
        'type' => 'leaf',
        'description' => 'Specifies the first display number available for sshd(8)\'s X11 forwarding. This prevents sshd from interfering with real X11 servers.'
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
        'compute' => {
          'formula' => '$main',
          'variables' => {
            'main' => '- - - &element'
          },
          'allow_override' => '1'
        },
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Specifies whether sshd(8) should bind the X11 forwarding server to the loopback address or to the wildcard address.  By default, sshd binds the forwarding server to the loopback address and sets the hostname part of the DISPLAY environment variable to "localhost". This prevents remote hosts from connecting to the proxy display.  However, some older X11 clients may not function with this configuration. X11UseLocalhost may be set to "no" to specify that the forwarding server should be bound to the wildcard address.',
        'choice' => [
          'yes',
          'no'
        ]
      }
    ]
  }
]
;

