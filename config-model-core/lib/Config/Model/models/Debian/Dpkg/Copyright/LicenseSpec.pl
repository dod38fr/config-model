[
  {
    'class_description' => 'Stand-alone license paragraph. This paragraph is used to describe licenses which are used somewhere else in the Files paragraph.',
    'accept' => [
      '.*',
      {
        'value_type' => 'string',
        'type' => 'leaf'
      }
    ],
    'name' => 'Debian::Dpkg::Copyright::LicenseSpec',
    'copyright' => [
      '2010',
      '2011 Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL2',
    'element' => [
      'text',
      {
        'value_type' => 'string',
        'type' => 'leaf',
        'description' => 'Full license text.'
      }
    ]
  }
]
;

