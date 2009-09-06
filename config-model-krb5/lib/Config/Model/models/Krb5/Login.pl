# $Author:$
# $Date: $
# $Name: $
# $Revision: $

#    Copyright (c) 2008 Peter Knowles
#
#    This file is part of Config::Model::Krb5.
#
#    Config::Model::Krb5 is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config::Model::Krb5 is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

# This model was created from krb5.conf(5) man page.

# Top level class feature krb5.conf sections

[
    [
        name => "Krb5::Login",

        'element' => [
            'krb5_get_tickets' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'Use password to get V5 tickets. Default value true.',
                'experience' => 'advanced',
            },

            'krb4_get_tickets' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'Use password to get V4 tickets. Default value false.',
                'experience' => 'advanced',
            },

            'krb4_convert' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'Use Kerberos conversion daemon to get V4 tickets. Default value false. If false, and krb4_get_tickets is true, then login will get the V5 tickets directly using the Kerberos V4 protocol directly. This does not currently work with non MIT-V4 salt types (such as the AFS3 salt type.) Note that if configuration parameter is true, and the krb524d is not running, login will hang for approximately a minute under Solaris, due to a Solaris socket emulation bug.',
                'experience' => 'advanced',
            },

            'krb_run_aklog' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'Attempt to run aklog. Default value false.',
                'experience' => 'advanced',
            },

            'aklog_path' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'Where to find it [not yet implemented.] Default value \$(prefix)/bin/aklog.',
                'experience' => 'advanced',
            },

            'accept_passwd' => {
                type         => 'leaf',
                value_type   => 'uniline',
                description  => 'Don\'t accept plaintext passwords [not yet implemented]. Default value false.',
                'experience' => 'advanced',
            },

        ],
    ],
];

