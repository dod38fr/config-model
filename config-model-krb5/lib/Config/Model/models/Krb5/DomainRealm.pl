[
          {
            'name' => 'Krb5::DomainRealm',
            'element' => [
                           'domains',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'hash',
                             'description' => 'A mapping between a hostname or a domain name (where domain names are indicated by a prefix of a period () character) and a Kerberos realm.',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
