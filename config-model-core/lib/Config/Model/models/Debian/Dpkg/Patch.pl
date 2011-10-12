[
  {
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
        'value_type' => 'uniline',
        'warn_if_match' => {
          '.{60,}' => {
            'msg' => 'Synopsis is too long. '
          }
        },
        'summary' => 'short description of the patch',
        'warn_unless' => {
          'empty' => {
            'code' => 'defined $_ && /\w/ ? 1 : 0 ;', 
            'msg' => 'Empty synopsis',
            'fix' => '$_ = ucfirst( $self->parent->index_value )  ;
s/-/ /g;
'
          }
        },
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
        'value_type' => 'uniline',
        'type' => 'leaf'
      },
      'Bug',
      {
        'value_type' => 'uniline',
        'type' => 'leaf'
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

