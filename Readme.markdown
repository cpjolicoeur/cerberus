# Description

Cerberus is a Continuous Integration software written in Ruby. Cerberus can be periodically run from scheduler to check if application tests are broken. In the case of test failure, Cerberus will send notification alerts via various methods. Cerberus perfectly works both on Windows and *nix platforms.

For more CI theory, [read this document from Martin Fowler][1].  

Cerberus's website is at [http://cerberus.rubyforge.org][6].

***

What does the 'Cerberus' name mean?
> Quote from Wikipedia (http://en.wikipedia.org/wiki/Cerberus)
>
> Cerberus or Kerberos (Kerberos, demon of the pit), was the hound of Hades-a monstrous three-headed dog (sometimes said to have 50 or 100 heads) with a snake for a tail and innumerable snake heads on his back.
He guarded the gate to Hades (the Greek underworld) and ensured that the dead could not leave and the living could not enter. His brother was Orthrus. He is the offspring of Echidna and Typhon.

So, put simply, Cerberus will guard your tests and not allow your project to go to the world of dead. 

***

There are several CI solutions already present, why do you need to use Cerberus?

Main advantages of Cerberus over other solutions include:

1. Cerberus could be installed on any machine not only where the repository is located.
2. Cerberus works not only for Rails projects, but for any other Ruby projects as well as for other platforms (Maven2 for Java)
3. Cerberus multi-platform solution: it runs excellent both on *nix and Windows.
4. Cerberus is distributed via RubyGems, making it very easy to install and very easy to update to the latest stable version
5. Cerberus is very easy to start using. Just type 'cerberus add PROJECT_URL|PROJECT_DIR'
6. Cerberus is a lightweight solution: a simple command line CI tool that only runs when the repository has changes

## Requirements

* ruby - 1.8.2 or higher
* rake - 0.7.3 or higher (optional)
* actionmailer - 2.0 or higher (optional)

## Usage
 
Cerberus is installed like any other Ruby gem.

    gem install cerberus

Alternatively, you can  get Cerberus in gem, zip or tarball right from [the RubyForge download page][5] 

Next, add a project that will be watched by Cerberus.

    cerberus add _REPOSITORY_

The repository can be either a file path or URL.  Additional parameters can be found in the [wiki][2].

Next, go to ~/.cerberus and edit the config.yml file (only needed once after installing Cerberus). Enter your configuration options here like email server, password, user_name and other options. See ActionMailer description - Cerberus uses it as notification layer. An example config file looks like this:

    publisher:
      mail:
        address: mail.someserver.com
        user_name: foobar
        password: foobaz
        domain: someserver.com
        authentication: login

Also check ~/.cerberus/config/<PROJECT_NAME>.yml and make sure that you have right settings specific to the project.

Next run Cerberus 

    cerberus build PROJECT_NAME    # Run project

or

    cerberus buildall     # Run all available projects


Cerberus will check out the latest repository sources and run tests for your project.  If tests fail, the notification alerts will be sent

You can also schedule Cerberus to run via CRON to automate the process.


## Features

Cerberus currently supports the following SCM tools: 

  * Subversion
  * Git
  * Darcs
  * Perforce
  * CVS
  * Bazaar
  * Mercurial

Cerberus currently supports the following notification systems: 

  * Email
  * Jabber
  * IRC
  * RSS
  * Campfire
  * Twitter

Cerberus currently supports the following build systems: 

  * Rake
  * Ruby script
  * RSpec
  * Rant
  * Maven2
  * Bjam
  

## Documentation

For instructions, guides and documentation, [please refer to the GitHub wiki][2].

## Mailing List / Public Forums

[http://groups.google.com/group/cerberusci][3]

## Issue Tracker

[http://cpjolicoeur.lighthouseapp.com/projects/22299-cerberus][4]

## License

This plugin is licensed under the MIT license. Complete license text
is included in the License.txt file.


[1]:http://www.martinfowler.com/articles/continuousIntegration.html
[2]:http://wiki.github.com/cpjolicoeur/cerberus
[3]:http://groups.google.com/group/cerberusci
[4]:http://cpjolicoeur.lighthouseapp.com/projects/22299-cerberus
[5]:http://rubyforge.org/frs/?group_id=1794
[6]:http://cerberus.rubyforge.org
