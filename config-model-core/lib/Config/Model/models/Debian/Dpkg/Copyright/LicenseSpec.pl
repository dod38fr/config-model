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
        'compute' => {
          'undef_is' => '\'\'',
          'use_eval' => '1',
          'formula' => 'require Software::License ;
my $l = Software::License({ short_name => $holder, holder => \'foo\') ;
$l->summary ;',
          'variables' => {
            'holder' => '-'
          },
          'allow_override' => '1'
        },
        'value_type' => 'string',
        'type' => 'leaf',
        'description' => 'Full license text.'
      }
    ]
  }
]
;

