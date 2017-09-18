[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'PARTICIPATE',
      {
        'description' => 'If you don\'t want to participate in the contest, say "no" and we won\'t send messages.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ENCRYPT',
      {
        'choice' => [
          'no',
          'maybe',
          'yes'
        ],
        'description' => 'encrypt popcon submission. Eventually, this feature wil be enabled by default.',
        'help' => {
          'maybe' => 'encrypt if gpg is available',
          'yes' => 'try to encrypt and fail if gpg is not available'
        },
        'summary' => 'support for encrypted submissions',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'MAILTO',
      {
        'description' => 'Specifies the address to e-mail statistics to each week.',
        'summary' => 'survey e-mail',
        'type' => 'leaf',
        'upstream_default' => 'survey@popcon.debian.org',
        'value_type' => 'uniline'
      },
      'MAILFROM',
      {
        'description' => 'MAILFROM is the forged sender email address you want to use in email submitted to the popularity-contest. If this is commented out, no From: or Sender: lines will be added to the outgoing mail, and it will be your MTA\'s job to add them. This is usually what you want.

If your MTA is misconfigured or impossible to configure correctly, and it always generates invalid From: and/or Sender: lines, you can force different results by setting MAILFROM here. This can cause problems with spam bouncers, so most people should leave it commented out.',
        'summary' => 'forged sender email address',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SUBMITURLS',
      {
        'description' => 'Space separated list of where to submit popularity-contest reports using http.',
        'summary' => 'list of urls to submit data to',
        'type' => 'leaf',
        'upstream_default' => 'http://popcon.debian.org/cgi-bin/popcon.cgi',
        'value_type' => 'uniline'
      },
      'USEHTTP',
      {
        'description' => 'enables http reporting. Set this to \'yes\' to enable it.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'HTTP_PROXY',
      {
        'description' => 'Allows one to specify an HTTP proxy server, the syntax is "http://proxy:port". This overrides the environment variable http_proxy.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MY_HOSTID',
      {
        'description' => 'Secret number that the popularity-contest receiver uses to keep track of your submissions. Whenever you send in a new entry, it overwrites the last one that had the same HOSTID.

This key was generated automatically so you should normally just leave it alone. ',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DAY',
      {
        'description' => 'Only run on the given day, to spread the load on the server a bit. 0 is Sunday, 6 is Saturday. ',
        'max' => '6',
        'summary' => 'day of week',
        'type' => 'leaf',
        'value_type' => 'integer'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'PopCon',
    'rw_config' => {
      'backend' => 'ShellVar',
      'config_dir' => '/etc',
      'file' => 'popularity-contest.conf'
    }
  }
]
;

