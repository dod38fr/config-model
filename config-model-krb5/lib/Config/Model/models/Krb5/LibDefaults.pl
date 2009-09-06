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
        name => "Krb5::LibDefaults",

        'element' => [
            'default_keytab_name' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This relation specifies the default keytab name to be used by application severs such as telnetd and rlogind. The default is "/etc/krb5.keytab". This formerly defaulted to "/etc/v5srvtab", but was changed to the current value.',
            },

            'default_realm' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'beginner',
                'description' => 'This relation identifies the default realm to be used in a client host\'s Kerberos activity.',
            },

            'default_tgs_enctypes' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This relation identifies the supported list of session key encryption types that should be returned by the KDC. The list may be delimited with commas or whitespace.',
            },

            'default_tkt_enctypes' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This relation identifies the supported list of session key encryption types that should be requested by the client, in the same format.',
            },

            'permitted_enctypes' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This relation identifies the permitted list of session key encryption types.',
            },

            'clockskew' => {
                type          => 'leaf',
                value_type    => 'integer',
                min           => '0',
                default       => '300',
                'experience'  => 'advanced',
                'description' => 'This relation sets the maximum allowable amount of clockskew in seconds that the library will tolerate before assuming that a Kerberos message is invalid. The default value is 300 seconds, or five minutes.',
            },

            'kdc_timesync' => {
                type          => 'leaf',
                value_type    => 'integer',
                'experience'  => 'advanced',
                'description' => 'If the value of this relation is non-zero (the default), the library will compute the difference between the system clock and the time returned by the KDC and in order to correct for an inaccurate system clock. This corrective factor is only used by the Kerberos library.',
            },

            'kdc_req_checksum_type' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'For compatability with DCE security servers which do not support the default CKSUMTYPE_RSA_MD5 used by this version of Kerberos. Use a value of 2 to use the CKSUMTYPE_RSA_MD4 instead. This applies to DCE 1.1 and earlier.',
            },

            'ap_req_checksum_type' => {
                type          => 'leaf',
                value_type    => 'integer',
                'experience'  => 'advanced',
                'description' => 'This allows you to set the checksum type used in the authenticator of KRB_AP_REQ messages. The default value for this type is CKSUMTYPE_RSA_MD5. For compatibility with applications linked against DCE version 1.1 or earlier Kerberos libraries, use a value of 2 to use the CKSUMTYPE_RSA_MD4 instead.',
            },

            'safe_checksum_type' => {
                type          => 'leaf',
                value_type    => 'integer',
                'experience'  => 'advanced',
                'description' => 'This allows you to set the preferred keyed-checksum type for use in KRB_SAFE messages. The default value for this type is CKSUMTYPE_RSA_MD5_DES. For compatibility with applications linked against DCE version 1.1 or earlier Kerberos libraries, use a value of 3 to use the CKSUMTYPE_RSA_MD4_DES instead. This field is ignored when its value is incompatible with the session key type.',
            },

            'preferred_preauth_types' => {
                type          => 'leaf',
                value_type    => 'uniline',
                default       => '17, 16, 15, 14',
                'experience'  => 'advanced',
                'description' => 'This allows you to set the preferred preauthentication types which the client will attempt before others which may be advertised by a KDC. The default value for this setting is "17, 16, 15, 14", which forces libkrb5 to attempt to use PKINIT if it is supported.',
            },

            'ccache_type' => {
                type          => 'leaf',
                value_type    => 'integer',
                'experience'  => 'advanced',
                'description' => 'User this parameter on systems which are DCE clients, to specify the type of cache to be created by kinit, or when forwarded tickets are received. DCE and Kerberos can share the cache, but some versions of DCE do not support the default cache as created by this version of Kerberos. Use a value of 1 on DCE 1.0.3a systems, and a value of 2 on DCE 1.1 systems.',
            },

            'krb4_srvtab' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'Specifies the location of the Kerberos V4 srvtab file. Default is "/etc/srvtab".',
            },

            'krb4_config' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'Specifies the location of the Kerberos V4 configuration file. Default is "/etc/krb.conf".',
            },

            'krb4_realms' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'Specifies the location of the Kerberos V4 domain/realm translation file. Default is "/etc/krb.realms".',
            },

            'dns_lookup_kdc' => {
                type          => 'leaf',
                value_type    => 'boolean',
                'experience'  => 'advanced',
                'description' => 'Indicate whether DNS SRV records shoud be used to locate the KDCs and other servers for a realm, if they are not listed in the information for the realm. The default is to use these records.',
            },

            'dns_lookup_realm' => {
                type          => 'leaf',
                value_type    => 'boolean',
                'experience'  => 'advanced',
                'description' => 'Indicate whether DNS TXT records should be used to determine the Kerberos realm of a host. The default is not to use these records.',
            },

            'dns_fallback' => {
                type          => 'leaf',
                value_type    => 'boolean',
                'experience'  => 'advanced',
                'description' => 'General flag controlling the use of DNS for Kerberos information. If both of the preceding options are specified, this option has no effect.',
            },

            'extra_addresses' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'This allows a computer to use multiple local addresses, in order to allow Kerberos to work in a network that uses NATs. The addresses should be in a comma-separated list.',
            },

            'udp_preference_limit' => {
                type          => 'leaf',
                value_type    => 'uniline',
                'experience'  => 'advanced',
                'description' => 'When sending a message to the KDC, the library will try using TCP before UDP if the size of the message is above "udp_preference_limit". If the message is smaller than "udp_preference_limit", then UDP will be tried before TCP. Regardless of the size, both protocols will be tried if the first attempt fails.',
            },

            'verify_ap_req_nofail' => {
                type          => 'leaf',
                value_type    => 'boolean',
                default       => '0',
                'experience'  => 'advanced',
                'description' => 'If this flag is set, then an attempt to get initial credentials will fail if the client machine does not have a keytab. The default for the flag is false.',
            },

            'renew_lifetime' => {
                type          => 'leaf',
                value_type    => 'integer',
                min           => '0',
                default       => '0',
                'experience'  => 'advanced',
                'description' => 'The value of this tag is the default renewable lifetime for initial tickets. The default value for the tag is 0.',
            },

            'noaddresses' => {
                type          => 'leaf',
                value_type    => 'boolean',
                default       => '1',
                'experience'  => 'advanced',
                'description' => 'Setting this flag causes the initial Kerberos ticket to be addressless. The default for the flag is true.',
            },

            'forwardable' => {
                type          => 'leaf',
                value_type    => 'boolean',
                default       => '0',
                'experience'  => 'advanced',
                'description' => 'If this flag is set, initial tickets by default will be forwardable. The default value for this flag is false.',
            },

            'proxiable' => {
                type          => 'leaf',
                value_type    => 'boolean',
                default       => '0',
                'experience'  => 'advanced',
                'description' => 'If this flag is set, initial tickets by default will be proxiable. The default value for this flag is false.',
            },

        ],

    ],
];
