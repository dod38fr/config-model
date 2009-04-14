[
          {
            'read_config' => [
                               {
                                 'file' => 'approx.conf',
                                 'backend' => 'custom',
                                 'class' => 'Config::Model::Approx',
                                 'config_dir' => '/etc/approx'
                               }
                             ],
            'name' => 'Approx',
            'element' => [
                           'max_rate',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'maximum download rate from remote repositories',
                             'type' => 'leaf',
                             'description' => "Specifies the maximum download rate from remote repositories, in bytes per second (default: unlimited). The value may be suf\x{2010} fixed with \"K\", \"M\", or \"G\" to indicate kilobytes, megabytes, or gigabytes per second, respectively."
                           },
                           'max_redirects',
                           {
                             'value_type' => 'integer',
                             'summary' => 'maximum number of HTTP redirections',
                             'built_in' => '5',
                             'type' => 'leaf',
                             'description' => 'Specifies the maximum number of HTTP redirections that will be followed when downloading a remote file'
                           },
                           'user',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'user that owns the files in the approx cache',
                             'built_in' => 'approx',
                             'type' => 'leaf'
                           },
                           'group',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'group that owns the files in the approx cache',
                             'built_in' => 'approx',
                             'type' => 'leaf'
                           },
                           'syslog',
                           {
                             'value_type' => 'uniline',
                             'summary' => 'syslog(3) facility to use when logging',
                             'built_in' => 'daemon',
                             'type' => 'leaf'
                           },
                           'pdiffs',
                           {
                             'value_type' => 'boolean',
                             'summary' => 'support IndexFile diffs',
                             'built_in' => '1',
                             'type' => 'leaf'
                           },
                           'offline',
                           {
                             'value_type' => 'boolean',
                             'summary' => 'use cached files when offline',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether to deliver (possibly out-of-date) cached files when they cannot be downloaded from remote repositories'
                           },
                           'max_wait',
                           {
                             'value_type' => 'integer',
                             'summary' => 'max wait for concurrent file download',
                             'built_in' => '10',
                             'type' => 'leaf',
                             'description' => 'Specifies how many seconds an approx(8) process will wait for a concurrent download of a file to complete, before attempting to download the file itself'
                           },
                           'verbose',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether informational messages should be printed in the log'
                           },
                           'debug',
                           {
                             'value_type' => 'boolean',
                             'built_in' => '0',
                             'type' => 'leaf',
                             'description' => 'Specifies whether debug messages should be printed in the log'
                           },
                           'distributions',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'summary' => 'remote repositories',
                             'type' => 'hash',
                             'description' => 'The other name/value pairs are used to map distribution names to remote repositories. For example,

  debian     =>   http://ftp.debian.org/debian
  security   =>   http://security.debian.org/debian-security

Use the distribution name as the key of the hash element and the URL as the value
',
                             'index_type' => 'string'
                           }
                         ]
          }
        ]
;
