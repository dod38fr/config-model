[
  {
    'accept' => [
      '\\w+',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Handling unknown parameter as unlinie value.'
      }
    ],
    'element' => [
      'packages',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      },
      'components',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'type' => 'list'
      },
      'source',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'keyring',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'suite',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'omitdebsrc',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'name' => 'Multistrap::Section'
  }
]
;

