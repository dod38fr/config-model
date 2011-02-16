[
          {
            'class_description' => 'Model of /etc/ssh/ssh_config or ~/.ssh/config',
            'include_after' => 'Host',
            'read_config' => [
                               {
                                 'backend' => 'OpenSsh::Ssh',
                                 'config_dir' => '/etc/ssh'
                               }
                             ],
            'name' => 'Ssh',
            'include' => [
                           'Ssh::HostElement'
                         ],
            'element' => [
                           'EnableSSHKeysign',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => '0',
                             'type' => 'leaf',
                             'description' => 'Setting this option to ``yes\'\' in the global client configuration file /etc/ssh/ssh_config enables the use of the helper program ssh-keysign(8) during HostbasedAuthentication.  See ssh-keysign(8)for more information.
'
                           },
                           'Host',
                           {
                             'level' => 'important',
                             'cargo' => {
                                          'type' => 'node',
                                          'config_class_name' => 'Ssh::HostElement'
                                        },
                             'ordered' => '1',
                             'type' => 'hash',
                             'description' => "The declarations make in 'parameters' are applied only to the hosts that match one of the patterns given in pattern elements. A single \x{2018}*\x{2019} as a pattern can be used to provide global defaults for all hosts. The host is the hostname argument given on the command line (i.e. the name is not converted to a canonicalized host name before matching). Since the first obtained value for each parameter is used, more host-specific declarations should be given near the beginning of the hash (which takes order into account), and general defaults at the end.",
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
