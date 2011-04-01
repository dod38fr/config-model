[
  {
    'read_config' => [
      {
        'file' => 'popularity-contest.conf',
        'backend' => 'ShellVar',
        'config_dir' => '/etc'
      }
    ],
    'name' => 'PopCon',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'PARTICIPATE',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'If you don\'t want to participate in the contest, say "no" and we won\'t send messages.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'MAILTO',
      {
        'value_type' => 'uniline',
        'summary' => 'survey e-mail',
        'upstream_default' => 'survey@popcon.debian.org',
        'type' => 'leaf',
        'description' => 'Specifies the address to e-mail statistics to each week.'
      },
      'MAILFROM',
      {
        'value_type' => 'uniline',
        'summary' => 'forged sender email address',
        'type' => 'leaf',
        'description' => 'MAILFROM is the forged sender email address you want to use in email submitted to the popularity-contest. If this is commented out, no From: or Sender: lines will be added to the outgoing mail, and it will be your MTA\'s job to add them. This is usually what you want.

If your MTA is misconfigured or impossible to configure correctly, and it always generates invalid From: and/or Sender: lines, you can force different results by setting MAILFROM here. This can cause problems with spam bouncers, so most people should leave it commented out.'
      },
      'SUBMITURLS',
      {
        'value_type' => 'uniline',
        'summary' => 'list of urls to submit data to',
        'upstream_default' => 'http://popcon.debian.org/cgi-bin/popcon.cgi',
        'type' => 'leaf',
        'description' => 'Space separated list of where to submit popularity-contest reports using http.'
      },
      'USEHTTP',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'enables http reporting. Set this to \'yes\' to enable it.',
        'choice' => [
          'no',
          'yes'
        ]
      },
      'HTTP_PROXY',
      {
        'value_type' => 'uniline',
        'type' => 'leaf',
        'description' => 'Allows to specify an HTTP proxy server, the syntax is "http://proxy:port". This overrides the environment variable http_proxy.'
      },
      'MY_HOSTID',
      {
        'value_type' => 'uniline',
        'experience' => 'master',
        'type' => 'leaf',
        'description' => 'Secret number that the popularity-contest receiver uses to keep track of your submissions. Whenever you send in a new entry, it overwrites the last one that had the same HOSTID.

This key was generated automatically so you should normally just leave it alone. '
      },
      'DAY',
      {
        'value_type' => 'integer',
        'summary' => 'day of week',
        'max' => '6',
        'type' => 'leaf',
        'description' => 'Only run on the given day, to spread the load on the server a bit. 0 is Sunday, 6 is Saturday. '
      }
    ]
  }
]
;

