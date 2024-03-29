# How to contribute #

## Ask questions ##

Yes, asking a question is a form of contribution that helps the author
to improve documentation.

Feel free to ask questions to the [author](mailto:ddumont@cpan.org)

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

## Source code structure ##

The main parts of this modules are:

* `lib/Config/Model/**.pm`: the core framework files
* `lib/Config/Model/Backend/**.pm`: classes used to read and write configuration files
* `lib/Config/Model/models/**.pl`: the model of the applications delivered with this module. These files can be modified with `cme meta edit` command. Their structure can be viewed with `cme meta gen-dot` and `dot -Tps model.dot > model.ps`
* `lib/Config/Model/models/**.pod`: the doc of the above models. Can be re-generated with `cme gen_class_pod`
* `t`: test files. Run the tests with `prove -l t`
* `t/model_tests.d` test the application delivered with this module using [Config::Model::Tester](http://search.cpan.org/dist/Config-Model-Tester/lib/Config/Model/Tester.pm). Use `prove -l t/model_test.t` command to run only model tests.

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
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output to the [author](mailto:ddumont@cpan.org)


## Edit source code from Debian source package or CPAN tarball ##

Non Debian users can also prepare a patch using CPAN tarball:

* Download tar file from http://search.cpan.org
* unpack tar file with something like `tar axvf Config-Model-2.086.tar.gz`
* jump in `cd Config-Model-2.086`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output the [author](mailto:ddumont@cpan.org)

## Provide feedback ##

Feedback is important. Please take a moment to rate, comment or add
stars to this project:

* [cme github](https://github.com/dod38fr/cme-perl)
* [config-model github](https://github.com/dod38fr/config-model) or [config-model cpan ratings](http://cpanratings.perl.org/rate/?distribution=Config::Model)
