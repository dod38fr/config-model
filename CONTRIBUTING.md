# How to contribute #

## Ask questions ##

Yes, asking a question is a form of contribution that helps the author
to improve documentation.

Feel free to ask questions by sending a mail to
[config-model-user mailing list](mailto:config-model-users@lists.sourceforge.net)

## Log a bug ##

Please report issue on the issue tracker that best match your problem. If you
don't know please use [cme issue tracker](https://github.com/dod38fr/cme-perl/issues).

Here are the dedicated trackers:

* problem with cme command: https://github.com/dod38fr/cme-perl/issues
* problem with `cme check|fix|edit openssh`: https://github.com/dod38fr/config-model-openssh/issues
* problem with `cme check|fix|edit systemd`: https://github.com/dod38fr/config-model-systemd/issues
* problem with `cme check|fix|edit systemd-user`: https://github.com/dod38fr/config-model-systemd/issues
* problem with `cme check|fix|edit lcdproc`: https://github.com/dod38fr/config-model-lcdproc/issues
* problem with `cme check|fix|edit approx`: https://github.com/dod38fr/config-model-approx/issues
* problem with `cme check|fix|edit dpkg`: run `reportbug libconfig-model-dpkg-perl`
* problem with `cme check|fix|edit popcon`: https://github.com/dod38fr/config-model/issues
* problem with `cme check|fix|edit multistrap`: https://github.com/dod38fr/config-model/issues
* problem with `cme meta edit`: https://github.com/dod38fr/config-model-itself/issues
* problem with cme GUI: https://github.com/dod38fr/config-model-tkui/issues

## Edit source code from github ##

If you have a github account, you can clone a repo and prepare a pull-request.

You can:

* run `git clone https://github.com/dod38fr/config-model/`
* edit files
* run `prove -l t` to run non-regression tests

There's no need to worry about `dzil`, `Dist::Zilla` or `dist.ini`
files. These are useful to prepare a new release, but not to fix bugs.

## Edit source code from Debian source package  ##

You can also prepare a patch using Debian source package:

For instance:

* download and unpack `apt-get source libconfig-model-perl`
* jump in `cd libconfig-model-perl-2.086`
* optional but useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output on [config-model-user mailing list](mailto:config-model-users@lists.sourceforge.net)


## Edit source code from Debian source package or CPAN tarball ##

Non Debian users can also prepare a patch using CPAN tarball:

* Download tar file from http://search.cpan.org
* unpack tar file with something like `tar axvf Config-Model-2.086.tar.gz`
* jump in `cd Config-Model-2.086`
* optional but useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output on [config-model-user mailing list](mailto:config-model-users@lists.sourceforge.net)

## Provide feedback ##

Feedback is important. Please take a moment to rate, comment or add
stars to this project:

* [cme github](https://github.com/dod38fr/cme-perl) or [cme cpan ratings](http://cpanratings.perl.org/rate/?distribution=App-Cme)
* [config-model github](https://github.com/dod38fr/config-model) or [config-model cpan ratings](http://cpanratings.perl.org/rate/?distribution=Config::Model)
