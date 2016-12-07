# Config-Model

Configuration schema on steroids.

[![](https://travis-ci.org/dod38fr/config-model.svg?branch=master)](https://travis-ci.org/dod38fr/config-model)
[![](https://badges.gitter.im/dod38fr/config-model.svg)](https://gitter.im/dod38fr/config-model?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# What is Config-Model project

[Config::Model](https://metacpan.org/pod/Config::Model) is:

* a set of configuration editor and validator for several projects like [OpenSSH](http://www.openssh.com/), [Systemd](https://freedesktop.org/wiki/Software/systemd/), [LcdProc](http://www.lcdproc.org/)...
See [full list of Configuration editors](https://github.com/dod38fr/config-model/wiki/Available-models-and-backends#Available_models_and_configuration_editors)
* a framework that enables a project developer (or any advance user) to provide a configuration editor and validator to his users.

To generate a configuration editor and validator for a project, [Config::Model](https://metacpan.org/pod/Config::Model) needs:

* a description of the structure and constraints of a project configuration. (this is called a model, but could also be called a schema)
* a way to read and write configuration data. This can be provided 
by [built-in read/write backends](https://github.com/dod38fr/config-model/wiki/Available-models-and-backends#Available_backend) or by a [new read/write backend](http://search.cpan.org/dist/Config-Model/lib/Config/Model/Backend/Any.pm#How_to_write_your_own_backend).

With the elements above, [Config::Model](https://metacpan.org/pod/Config::Model) generates interactive
configuration editors (with integrated help and data validation)
and support several kinds of user interface, e.g. graphical, interactive
command line. See the [list of available user interfaces](https://github.com/dod38fr/config-model/wiki/Available-models-and-backends#Available_user_interfaces)

## Installation

See [installation instructions](https://github.com/dod38fr/config-model/blob/master/README.install.pod)

## Getting started

* To manage your configuration files with existing modules, see [Using cme wiki page](https://github.com/dod38fr/config-model/wiki/Using-cme)
* To create configuration tools for your favorite project, see this [introduction to model creation](https://metacpan.org/pod/Config::Model::Manual::ModelCreationIntroduction)

## How does this work ?

Using this project, a typical configuration editor will be made of 3
parts :

1. The user interface ( [cme](http://search.cpan.org/dist/Config-Model/script/cme) program and some other optional modules)
2. The validation engine which is in charge of validating all the configuration information provided by the user. This engine is made of the framework provided by this module and the configuration description (often referred as "configuration model", this could also be known as a schema).
3. The storage facility that store the configuration information (currently several backends are provided: ini files, perl files)

The important part is the configuration model used by the validation
engine. This model can be created or modified with a graphical editor
([cme meta edit](http://search.cpan.org/dist/Config-Model-Itself/lib/App/Cme/Command/meta.pm)
provided by [Config::Model::Itself](https://metacpan.org/pod/Config::Model::Itself)).

## Don't we already have some configuration validation tools ?

You're probably thinking of tools like webmin. Yes, these tools exist
and work fine, but they have their set of drawbacks.

Usually, the validation of configuration data is done with a script
which performs semantic validation and often ends up being quite
complex (e.g. 2500 lines for Debian's xserver-xorg.config script which
handles xorg.conf file). 

In most cases, the configuration model is expressed in instructions
(whatever programming language is used) and interspersed with a lot of
processing to handle the actual configuration data.

## What's the advantage of this project ?

[Config::Model](https://metacpan.org/pod/Config::Model) projects provide a way to get a validation engine where
the configuration model is completely separated from the actual
processing instructions.

A configuration model can be created and modified with the graphical
interface provided by ["cme meta edit"](#cme-meta-edit) distributed with
[Config::Model::Itself](https://metacpan.org/pod/Config::Model::Itself). The model is saved in a
declarative form (currently, a Perl data structure). Such a model is
easier to maintain than a lot of code.

The model specifies:

* the structure of the configuration data (which can be queried by generic user interfaces)
* the properties of each element (boundaries check, integer or string, enum like type ...)
* the default values of parameters (if any)
* mandatory parameters
* Warning conditions (and optionally, instructions to fix warnings)
* on-line help (for each parameter or value of parameter)

So, in the end:

* maintenance and evolution of the configuration content is easier
* user will see a **common** interface for **all** programs using this project.
* upgrade of configuration data is easier and sanity check is performed
* audit of configuration is possible to check what was modified by the user compared to default values

## What about the user interface ?

[Config::Model](https://metacpan.org/pod/Config::Model) interface can be:

* a shell-like interface (plain or based on [Term::ReadLine](https://metacpan.org/pod/Term::ReadLine) with [Config::Model::TermUI](https://metacpan.org/pod/Config::Model::TermUI)).
* Graphical with [Config::Model::TkUI](https://metacpan.org/pod/Config::Model::TkUI) (Perl/Tk interface).
* based on curses with [Config::Model::CursesUI](https://metacpan.org/pod/Config::Model::CursesUI).

All these interfaces are generated from the configuration model.

And configuration model can be created or modified with a graphical
user interface (["cme meta edit"](#cme-meta-edit))

## What about configuration data storage ?

Since the syntax of configuration files vary wildly form one program
to another, most people who want to use this framework will have to
provide a dedicated parser/writer. 

Nevertheless, this project provides a writer/parser for some common
format: ini style file and perl file. 

## If you want to discuss Config::Model ?

* Subscribe to the config-model-users list: [http://lists.sourceforge.net/mailman/listinfo/config-model-users](http://lists.sourceforge.net/mailman/listinfo/config-model-users)

* [![Codewake](https://www.codewake.com/badges/ask_question.svg)](https://www.codewake.com/p/config-model)


## More information

See

* the [config-model wiki](https://github.com/dod38fr/config-model/wiki) (i.e. the wiki tab above)
* [https://ddumont.wordpress.com/category/perl/configmodel/](https://ddumont.wordpress.com/category/perl/configmodel/)
