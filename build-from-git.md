# How to build Config::Model from git repository

`Config::Model` is build with [Dist::Zilla](http://dzil.org/). This
pages details how to install the tools and dependencies required to
build this module.

## Install tools and dependencies

### Debian, Ubuntu and derivatives

Run

    $ sudo apt install libdist-zilla-perl libdist-zilla-app-command-authordebs-perl
    $ dzil authordebs --install
    $ sudo apt build-dep libconfig-model-perl

The [libdist-zilla-app-command-authordebs-perl package](https://tracker.debian.org/pkg/libdist-zilla-app-command-authordebs-perl) is quite recent (uploaded on Dec 2016 in Debian/unstable) 
and may not be available yet on your favorite distribution.

### Other systems

Run 

    $ cpamn Dist::Zilla
    $ dzil authordeps -missing | cpanm --notest
    $ cpanm --quiet --notest --skip-satisfied MouseX::NativeTraits
    $ dzil listdeps --missing | cpanm --notest

NB: The author would welcome pull requests that explains how to
install these tools and dependencies using native package of other
distributions.

## Build Config::Model

Run

    dzil build 

or 

    dzil test

`dzil` may complain about missing `EmailNotify` or `Twitter`
plugin. You may ignore this or edit [dist.ini](dist.ini) to comment
out the last 2 sections. These are useful only to the author when
releasing a new version.


`dzil` may also return an error like `Cannot determine local time
zone`. In this case, you should specify explicitely your timezone in
a `TZ` environement variable. E.g run `dzil` this way:

    TZ="Europe/Paris" dzil test

The list of possible timezones is provided by
[DateTime::TimeZone::Catalog](https://metacpan.org/pod/DateTime::TimeZone::Catalog)
documentation.

