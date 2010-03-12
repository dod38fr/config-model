[
          {
            'name' => 'Krb5::Login',
            'element' => [
                           'krb5_get_tickets',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Use password to get V5 tickets. Default value true.'
                           },
                           'krb4_get_tickets',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Use password to get V4 tickets. Default value false.'
                           },
                           'krb4_convert',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Use Kerberos conversion daemon to get V4 tickets. Default value false. If false, and krb4_get_tickets is true, then login will get the V5 tickets directly using the Kerberos V4 protocol directly. This does not currently work with non MIT-V4 salt types (such as the AFS3 salt type.) Note that if configuration parameter is true, and the krb524d is not running, login will hang for approximately a minute under Solaris, due to a Solaris socket emulation bug.'
                           },
                           'krb_run_aklog',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Attempt to run aklog. Default value false.'
                           },
                           'aklog_path',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Where to find it [not yet implemented.] Default value \\$(prefix)/bin/aklog.'
                           },
                           'accept_passwd',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'description' => 'Don\'t accept plaintext passwords [not yet implemented]. Default value false.'
                           }
                         ]
          }
        ]
;
