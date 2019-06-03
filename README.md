# serverspec_launcher

Serverspec launcher is utility for managing serverspec tests across servers, virtual machines, 
and containers using a YAML based configuration files.

It allows for spec files (or lists of shared behaviours) to be ran across groups of servers. 

It will generate rake tasks 

Serverspec launcher also has limited support for running inspec based checks, running via the [chef/inspec](https://hub.docker.com/r/chef/inspec/) docker image

## Requirements

* Ruby >= 2.3
* bundler 
* docker (if using inspec tests)


Currently this only runs on linux, possibly OS X (I don't have a mac to test it with)
 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'serverspec_launcher'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install serverspec_launcher

## Usage

### Setup

Run ```serverspec_launcher init``` from your applications root directory then add:

to spec/spec_helper.rb
```ruby
require 'serverspec_launcher/spec_helper'
```
to Rakefile
```ruby
require 'serverspec_launcher/rake_tasks'
```

### properties.yml
The properties.yml file contains the configuration for your test setup, it consists of a number of sections.

##### targets
The target section defines the targets (server, container), under test and consists of one or more hashes 
defining the tests. Serverspec launcher will generate a rake task for each target it finds within 
the target section, and a task for any hosts specifed within the targets config.  

Each target consists of:

###### Serverspec

targetname (hash key): (required) The name of the target
* backend: (optional) Which backend to run against, supported backend are ssh, exec, docker, vagrant, and inspec. Windows based backend will be availible in future versions
* user: (optional) what user to run the tests as, Defaults to current user
* hosts: (optional) list or single value specifying the hostname(s) to run this against. defaults to target name 
* spec_type: (optional) which spec file from the spec directory to execute against the target (do not include the _spec.rb). Defaults to role
* roles: (optional/mandatory if using role spec_type) list of shared behaviors (see below), to run against the target
* variables: (optional) hash of variables available to the the tests. Each variable specified here will be availible as property[:variables][:name_of_variable]. 
Any values specified here will overwrite environment level(not to be confused with environment variables), and global level variables
* environment: (optional) hash of environment variables which will be set on the target, environment level(not to be confused with environment variables), and global level environment varaibles(see below) that have previously defined values will be overwritten
* fail_on_err: Stop running the tests if the target fails its checks
* formatters: Use specific formatters for this target ([see formatters in option section](#options))

Example :

This would create the rake tasks serverspec:webservers, serverspec:webservers:webserver1 and serverspec:webservers:webserver2
```yaml
targets: 
  webservers: # the name of the target
    backend: ssh # use the 'ssh' backend.
    user: ec2-user
    hosts:
      - webserver1
      - webserver2
    spec_type: webserver  
```

###### Inspec

targetname (hash key): (required) The name of the target
* backend: (optional) Which backend to run against, this should be set to inspec
* user: (optional) what user to run the tests as, Defaults to current user
* hosts: (optional) list or single value specifying the hostname(s) to run this against. defaults to target name 
* spec_type: (optional) which spec file from the spec directory to execute against the target (do not include the _spec.rb). If control or profile are specifed this field is ignored
* control: (optional) path to inspec control to execute against the target (specify full path to spec file from project root). If profile is specified this field is ignored
* profile: (optional) path to inspec profile to execute against the target (specify full path to profile from project root, github or chef supermarket). If profile is specified this field is ignored
* fail_on_err: (optional) Stop running the tests if the target fails its checks
* auth_method: How to authenticate the target user
    * ssh-key: use an ssh key for authentication
    * agent: (recommened) Use an existing ssh agent as the authentication method
* keyfile: Space separated list ssh-key(s) to use for authentication if using ssh-key as the authentication method
* bastion_host: (optional) Specify a bastion host 
* bastion_user: (optional) Specify the user for a bastion host
* bastion_port: (optional) Specify the port for a bastion host
* formatters: Use specific reporters for this target ([see formatters in option section](#options))


Examples :

This would create the rake tasks serverspec:security, serverspec:security:webserver1 and serverspec:security:webserver2
which run test contained in spec/webserver_spec.rb
```yaml
targets: 
  security: # the name of the target
    backend: inspec # use the 'inspec' backend.
    user: ec2-user
    auth_method: agent
    hosts:
      - webserver1
      - webserver2
    spec_type: webserver  
```
This would create the rake tasks serverspec:security, serverspec:security:env01 and serverspec:security:env02
which run tests contained in spec/ssh_access.rb
```yaml
targets: 
  security: # the name of the target
    backend: inspec # use the 'inspec' backend.
    user: ec2-user
    auth_method: agent
    hosts:
      - env01
      - env02
    control: spec/ssh_access.rb 
```
This would create the rake tasks serverspec:security, serverspec:security:env01 and serverspec:security:env02
which run the CIS Distribution Independent Linux Benchmark profile against the target
```yaml
targets: 
  security: # the name of the target
    backend: inspec # use the 'inspec' backend.
    user: ec2-user
    auth_method: agent
    hosts:
      - env01
      - env02
    control: https://github.com/dev-sec/cis-dil-benchmark
```


##### environments
serverspec_launcher supports the concept of environments. Environments are groups of targets organised as a named entity, i.e. test or qa.

An environment consists of the following:

environment name (hash key): (required) the name of the environment
* targets: a hash of targets (see above for target definition)
* variables: (optional) hash of variables available to the the tests. Each variable specified here will be availible as property[:variables][:name_of_variable]. 
Any values specified here will override global level variables previously defined.
* environment: (optional) hash of environment variables which will be set on the target, global level environment varaibles(see below) that have previously defined values will be overwritten

Example:
```yaml
environments:
  qa:
    targets:
      webservers: &webservers
        hosts:
          - web1.qa.domain
          - web2.qa.domain
        variables:
          some_thing: new value # Override variable
    variables:
        my_var: enviroment value  # Override global variable
        some_thing: a value
          
  performance:
    targets:
      webservers:
        # Yaml anchors are supported
        <<: *webservers
        hosts:
        - web1.perf.domain
        - web2.perf.domain
        - web3.perf.domain
        - web4.perf.domain
```
<a name="options"></a>
##### options
A hash of options to pass to serverspec_launcher

* fail_on_err: (optional) stop testing after the first target failure, defaults to true
* color: (optional) colorize the output, defaults to true
* formatters: (optional) list of RSpec formatter to process the results with. Supported formatters are:

    - docs  RSpec Documentation Formatter writing to file reports/[\<environment\>]/\<target>/\<host>.docs. 
    If using inspec checks this will use the 'Documentation' reporter.
    - docs_screen - RSpec Documentation Formatter writing to screen. If using inspec checks this will use the 'Documentation' reporter.
    - tick -  Tick/Cross output to screen. If using inspec checks this will use the 'cli' reporter.
    - tick_file - Tick/Cross output to reports/[\<environment\>]/\<target>/\<host>.tick. If using inspec checks this will use the 'cli' reporter.
    - html - HTML Reports to reports/[\<environment\>]/\<target>/\<host>.html. If using inspec checks this will use the 'html' reporter.
    - junit - Unit Reports (useful for jenkins jobs) to 
    - html_pretty - Pretty HTML Reports to reports/[\<environment\>]/\<target>/\<host>.html. If using inspec checks this will use the 'html' reporter.
    - json - JSON Output to reports/[\<environment\>]/\<target>/\<host>.html. If using inspec checks this will use the 'html' reporter.
    - progress -  RSpec .F* progress output

Example:
```yaml
options:
  fail_on_err: false
  colorize: true
  formatters:
    - tick
    - docs

```
##### variables
A hash containing key value pairs. Each entry will be available as property[:variables][:\<key>]

Example:
```yaml
variables:
  my_var: some value
```
##### environment
A hash containing key value pairs. Each entry will be available as an envirment variable on the target
Example:
```yaml
environment:
  JAVA_HOME: /usr/lib/java-1.7
```
##### Complete Example
```yaml
options:
  # Stop the test on the first failure (default: true)
  fail_on_err: true
  # Specify output format defaults is docs_screen multiple formatters can be specified
  formatters:
    # RSpec Documentation Formatter writing to file reports/<target>.docs
    - docs
    # RSpec Documentation Formatter writing to screen
    - docs_screen
    # Tick/Cross output to screen
    - tick
    # Tick/Cross output to file reports/<target>.tick
    - tick_file
    # JUnit Reports
    - junit
    # HTML Reports
    - html
    # Pretty HTML Reports
    - html_pretty
    # JSON Output
    - json
    # RSpec .F* progress bar
    - progress
  # Use colorized output (default: true)
  color: false

# Load shared examples from third party gems, useful for sharing infrastucture tests 
# across projects
shared_example_gems:
  - my_shared_examples

# Specify environment variables used on the hosts when testing
# these are available as ENV['<var name>'] from the tests
environment:
  SOMEVAR: some value

# Specify variable to be used in the tests
# these are available from the tests as property[:variables][:<variable name>]
variables:
  my_var: some value


# Target Based Testing
# For each target specified here there will be a rake task defined which can be invoked via 'serverspec:<target name>'.
# Targets with multiple hosts will also have 'serverspec:<target name>:<hostname>' defined for each host.
# Running 'serverspec:<target name>' will execute against all hosts in the target
# Running the 'serverspec' rake task will invoke all targets and environments

targets:
  # Running against a host via ssh
  ssh-example:
    backend: ssh
    # specify host if left blank will use target name as hostname
    hosts: raspberrypi
    # uses specific user
    user: pi
    # run spec file spec/pi_spec.rb
    spec_type: pi
  
  # Running against multiple hosts via ssh
  ssh-multi-host-example:
    # Dont really need to specify ssh backend as it is the default but including for completeness
    hosts:
      - raspberrypi
      - blueberrypi
    # uses specific user
    user: pi
    # run spec file spec/pi_spec.rb
    spec_type: pi
    # Don't fail the run if the target fails (if blank uses the global value which defaults to true)
    fail_on_err: true

  # Run against local host  
  exec-example:
    backend: exec
    # Run spec file spec/localhost_spec.rb
    spec_type: localhost
    # Specify variable to be used in tests as property[:variables][:<variable name>]
    variables:
      # Specify a new variable
      some_var: some value
      # Override an existing vale
      my_var: new value

  # Run tests against a docker images
  docker-image-example:
    backend: docker
    # Run against the mongo docker image from docker hub
    docker_image: mongo
    # Use shared behaviors loaded from spec/shared/.rb
    roles:
      - database::mongo

  # Run tests against a running docker container
  docker-container-examples:
    backend: docker
    # Run against container named jenkins
    docker_container: jenkins
    # Explicitly specify the role spec file spec/role_spec.rb which should be generated by 'serverspec_launcher init'
    # This isn't really needed as role is the default spec_type
    spec_type: role
    roles:
      # Run role with in context
      - name: build_tools::jenkins
        description: Jenkins Container

  # Run tests against a docker build file
  dockerfile-examples:
    backend: docker
    # Build image from Dockerfile in current directory
    docker_build_dir: .
    # Run spec file spec/docker_spec.rb
    spec_type: docker


  # Run tests against a vagrant file
  vagrant-example:
    backend: vagrant
    roles:
    - debug::environment_vars
    environment:
      # This environment var will only be availble to this target
      MY_VAR: my value
      # Override a globally set environment var
      SOMEVAR: some other value

  inspec-profile-example: # the name of the target
    backend: inspec 
    user: ec2-user
    auth_method: agent
    hosts:
      - env01
      - env02
    profile: https://github.com/dev-sec/cis-dil-benchmark
 
   inspec-control-example: # the name of the target
     backend: inspec 
     user: ec2-user
     auth_method: agent
     hosts:
       - env01
       - env02
     control: spec/ssh_access.rb   

   inspec-spec-example: # the name of the target
     backend: inspec
     user: ec2-user
     auth_method: agent
     hosts: env01
     spec_type: webserver  
    
environments:
  qa:
    variables:
      # Override global variable
      my_var: enviroment value
      some_thing: a value

    targets:
      webservers: &webservers
        hosts:
          - web1.qa.domain
          - web2.qa.domain
        variables:
          # Override variable
          some_thing: new value

  performance:
    targets:
      webservers:
        # Yaml anchors are supported
        <<: *webservers
        hosts:
        - web1.perf.domain
        - web2.perf.domain
        - web3.perf.domain
        - web4.perf.domain
        variables:
          # Override variable
          some_thing: new value
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrewwardrobe/serverspec_launcher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

