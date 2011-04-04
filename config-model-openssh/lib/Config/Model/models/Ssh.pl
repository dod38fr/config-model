[
  {
    'class_description' => 'Configuration class used by L<Config::Model> to edit or 
validate /etc/ssh/ssh_config (when run as root)
or ~/.ssh/config (when run as a regular user).
',
    'include_after' => 'Host',
    'name' => 'Ssh',
    'include' => [
      'Ssh::HostElement'
    ],
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
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
    ],
    'read_config' => [
      {
        'backend' => 'OpenSsh::Ssh',
        'config_dir' => '/etc/ssh'
      }
    ]
  }
]
;

