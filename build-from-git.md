Config::Model from git is built with Dist::Zilla.

You must make sure that the following modules are installed:
Dist::Zilla::Plugin::MetaResources
Dist::Zilla::Plugin::ModuleBuild::Custom
Dist::Zilla::Plugin::Test::PodSpelling
Dist::Zilla::Plugin::PodVersion
Dist::Zilla::Plugin::Prepender
Dist::Zilla::Plugin::Prereqs
Dist::Zilla::Plugin::Run::BeforeBuild
Dist::Zilla::PluginBundle::Filter
Dist::Zilla::Plugin::Git::NextVersion
Config::Model::Tester

On debian or ubuntu, do:

sudo aptitude install \
     libdist-zilla-plugin-prepender-perl \
     libdist-zilla-plugin-run-perl \
     libdist-zilla-plugins-cjm-perl \
     libdist-zilla-perl \
     libdist-zilla-plugin-podspellingtests-perl \
     libdist-zilla-plugin-git-perl \
     libconfig-model-tester-perl

On other systems, run:

$ sudo perl -MCPAN -e shell
> install App::cpanminus
> quit
$ sudo cpamn install Dist::Zilla::Plugin::MetaResources
$ sudo cpamn install Dist::Zilla::Plugin::ModuleBuild::Custom
$ sudo cpamn install Dist::Zilla::Plugin::Test::PodSpelling
$ sudo cpamn install Dist::Zilla::Plugin::PodVersion
$ sudo cpamn install Dist::Zilla::Plugin::Prepender
$ sudo cpamn install Dist::Zilla::Plugin::Prereqs
$ sudo cpamn install Dist::Zilla::Plugin::Run::BeforeBuild
$ sudo cpamn install Dist::Zilla::PluginBundle::Filter
$ sudo cpamn install Dist::Zilla::Plugin::Git::NextVersion
$ sudo cpamn install Config::Model::Tester

Then run:

dzil build 

or 

dzil test

If dzil complains about missing EmailNotify or Twitter plugin, edit dist.ini and comment out
the last 2 sections. They are useful only to the author.

If dzil returns an error like "Cannot determine local time zone", you should
specify explicitely your timezone in TZ environement variable. E.g.

 TZ="Europe/Paris" dzil test

The list of timezones is provided by DateTime::TimeZone::Catalog documentation.

