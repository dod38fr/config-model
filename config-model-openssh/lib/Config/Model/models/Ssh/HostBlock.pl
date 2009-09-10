[
          {
            'name' => 'Ssh::HostBlock',
            'element' => [
                           'patterns',
                           {
                             'level' => 'important',
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'A pattern consists of zero or more non-whitespace characters, \'*\' (a wildcard that matches zero or more characters), or \'?\' (a wildcard that matches exactly one character).  For example, to specify a set of declarations for any host in the ".co.uk" set of domains, the following pattern could be used:

   Host *.co.uk

The following pattern would match any host in the 192.168.0.[0-9] network range:

   Host 192.168.0.?

A pattern-list is a comma-separated list of patterns. Patterns within pattern-lists may be negated by preceding them with an exclamation mark (\'!\'). For example, to allow a key to be used from anywhere within an organisation except from the "dialup" pool, the following entry (in authorized_keys) could be used:

   from="!*.dialup.example.com,*.example.com"
'
                           },
                           'block',
                           {
                             'level' => 'important',
                             'type' => 'node',
                             'description' => 'Specifies the parameters that apply to the host that match one of the pattern given above',
                             'config_class_name' => 'Ssh::HostElement'
                           }
                         ]
          }
        ]
;
