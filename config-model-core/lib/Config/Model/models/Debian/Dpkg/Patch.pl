[
  {
    'accept' => [
      'Bug-.*',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list',
        'accept_after' => 'Bug' ,
      }
    ],
    'read_config' => [
      {
        'backend' => 'Debian::Dpkg::Patch',
        'config_dir' => 'debian/patches'
      }
    ],
    'name' => 'Debian::Dpkg::Patch',
    'element' => [
      'Synopsis',
      {
        'warn_unless' => {
          'empty' => {
            'msg' => 'Empty synopsis',
            'fix' => '$_ = ucfirst( $self->parent->index_value )  ;
s/-/ /g;
',
            'code' => 'defined $_ && /\\w/ ? 1 : 0 ;'
          }
        },
        'value_type' => 'uniline',
        'warn_if_match' => {
          '.{60,}' => {
            'msg' => 'Synopsis is too long. '
          }
        },
        'summary' => 'short description of the patch',
        'type' => 'leaf'
      },
      'Description',
      {
        'value_type' => 'string',
        'type' => 'leaf',
        'description' => 'verbose explanation of the patch and its history.'
      },
      'Subject',
      {
        'value_type' => 'string',
        'type' => 'leaf'
      },
      'Bug',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'type' => 'list'
      },
      'Forwarded',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Author',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Origin',
      {
        'value_type' => 'string',
        'type' => 'leaf'
      },
      'From',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Reviewed-by',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Acked-by',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Last-Update',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Applied-Upstream',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'diff',
      {
        'value_type' => 'string',
        'summary' => 'actual patch',
        'type' => 'leaf',
        'description' => 'This element contains the diff that will be used to patch the source. Do not modify.'
      }
    ]
  }
]
;

