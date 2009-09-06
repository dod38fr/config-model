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

[
    [
        name => "Krb5::Logging::LoggingConfig",

        'element' => [
            'logging_type' => {
                'value_type' => 'enum',
                'help'       => {
                    'FILE'    => 'This value causes the entity\'s logging messages to go to the specified file',
                    'STDERR'  => 'This value causes the entity\'s logging messages to go to its standard error stream.',
                    'CONSOLE' => 'This value causes the entity\'s logging messages to go to the console, if the system supports it.',
                    'DEVICE'  => 'This causes the entity\'s logging messages to go to the specified device.',
                    'SYSLOG'  => 'This causes the entity\'s logging messages to go to the system log.',
                },
                'experience'  => 'advanced',
                'type'        => 'leaf',
                'description' => 'Specifies whether remote hosts are allowed to connect to ports forwarded for the client. By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.',
                'choice'      => [ 'FILE', 'STDERR', 'CONSOLE', 'DEVICE', 'SYSLOG', ]
            },

            'logging_config' => {
                type          => 'warped_node',
                'experience' => 'advanced',
                follow        => '- logging_type',
                'rules'       => {
                    'FILE'    => { config_class_name => 'Krb5::Logging::LoggingConfig::File' },
                    'STDERR'  => { config_class_name => 'Krb5::Logging::LoggingConfig::StdErr' },
                    'CONSOLE' => { config_class_name => 'Krb5::Logging::LoggingConfig::Console' },
                    'DEVICE'  => { config_class_name => 'Krb5::Logging::LoggingConfig::Device' },
                    'SYSLOG'  => { config_class_name => 'Krb5::Logging::LoggingConfig::Syslog' },
                }
            },
        ],
    ],
];

