# puppet module

[![Build Status](https://travis-ci.org/spiette/puppet-puppet.png?branch=master)](https://travis-ci.org/spiette/puppet-puppet)

This is a puppet module. It is meant to be used on nodes as well as puppetmasters. Current feature set:

* Debian and RedHat family supported
* Always enable the client
* Configure a CA or non-CA puppetmaster
* Works with passenger or with puppetmaster standalone
* Works well with puppetlabs/puppetdb modules
* agent_options and master_options hash to set arbitrary options to agent and master

The puppetmaster with passenger uses puppetlabs package, which means that it is not as robust as a pure puppet-based recipe.

# Synopsis

Except for configuration parameters, only the top puppet class should invoked. Use the `master` parameter to enable the puppetmaster.

## puppet class

### Parameters

- *certname*
  Same as puppet configuration parameter. Set the certificate name that the puppetmaster will see and, if applicable, the puppetmaster will have.

- *server*
  Same as puppet configuration parameter. Server used by the puppet agent. 

- *master*
  Boolean, false by default. If true, the node will be configured as a puppetmaster.

- *manage_service*
  Boolean, true by default. If you set it to false, the proper service (apache2 or puppetmaster) will not be declared and managed by this module. It is useful in case of conflict with the puppetdb module.

- *passenger*
  If passenger (and master) is true, the puppetmaster will have Apache and passenger in frontend. Use this if you want to serve more than a couple of nodes.

- *manage_passenger*
  Boolean, true by default. If $passenger is true, but you do not want Puppet to manage it (only install the puppetmaster-passenger package), you can set this to false.

- *autosign*
  Same as puppet configuration parameter. Use this for automated testing.

- *puppetdb*
  If true, it will set the proper storeconfig configuration. It wil _not_ set puppetdb, use puppetlabs module for that.

- *ca*
  Used by a puppetmaster to set it as the CA or not.

- *ca_server*
  Used by the agent for certificate management. See http://docs.puppetlabs.com/guides/scaling_multiple_masters.html for more details.

- *master_options*
  Hash used to add any additionnal configuration settings for the master. See http://docs.puppetlabs.com/references/latest/configuration.html

- *agent_options*
  Hash used to add any additionnal configuration settings for the agent. See http://docs.puppetlabs.com/references/latest/configuration.html

# Usage

### For puppet agents

    class { 'puppet':
      certname => 'puppet.local.lan',
      server   => 'puppet.local.lan',
      agent_options => {
        'runinterval => '900',
        'splay' => true,
      }
    }

### For puppet server, using webrick. The fqdn is not the certname of the puppetmaster.

    $servername = 'puppet.local.lan'
    host { $::fqdn:
      ip           => $::ipaddress_eth0,
      host_aliases => [ $::hostname, $servername ],
    }
    class { 'puppet':
      master    => true,
      certname  => $servername,
      passenger => false,
      agent_options => {
        'runinterval => '900',
        'splay' => true,
      }
      master_options => {
        'manifest' => '/etc/puppet/environments/$environment/site.pp',
        'modulepath' => '/etc/puppet/environments/$environment/modules:/etc/puppet/environments/$environment/site',
      }
    }

### For puppet server, using passenger. The fqdn is not the certname of the puppetmaster.

    $servername = 'puppet.local.lan'
    host { $::fqdn:
      ip           => $::ipaddress_eth0,
      host_aliases => [ $::hostname, $servername ],
    }
    class { 'puppet':
      certname  => $servername,
      master    => true,
      passenger => true,
    }

### How to use with puppetdb

Here is an example bootstrapping sequence for Ubuntu Trusty:

    # make sure locales are correctly configured:
    for i in $(env |grep ^LC_[A-Z]*= |sed 's/^LC_[A-Z]*=//' | sort -u); do locale-gen $i; done
    apt-get -y install puppet git
    
    # Download puppet modules for bootstrap
    BS=/root/bootstrap
    mkdir -p $BS/modules
    cd $BS
    puppet module --modulepath $BS/modules install puppetlabs-puppetdb
    git clone https://github.com/spiette/puppet-puppet.git $BS/modules/puppet
    cd modules/puppet
    git checkout trusty
    cd $BS
    
    # Bootstrapping code
    cat >bootstrap.pp <<EOF
    apt::source { 'puppetlabs':
      location   => 'http://apt.puppetlabs.com',
      repos      => 'main dependencies',
      key        => '4BD6EC30',
      key_server => 'pgp.mit.edu',
    }
    Class['Apt::Update'] -> Package <| |>
    
    Class['Puppet'] -> Class['Puppetdb']
    
    class { 'puppetdb': }
    class { 'puppetdb::master::config':
      puppet_service_name      => 'apache2',
      puppetdb_startup_timeout => '30',
    }
    class { 'puppet':
      certname  => $::fqdn,
      server    => $::fqdn,
      master    => true,
      puppetdb  => true,
      manage_service => false,
      manage_passenger => false,
      passenger => true,
    }
    EOF
    
    # You may need to run the following command 2 or more times
    # for postgresql/puppetdb to be running correctly
    puppet apply --modulepath=/root/bootstrap/modules bootstrap.pp
    
    # You are now ready to populate your puppet environment (in /etc/puppet/environments/production)
    mkdir -p /etc/puppet/environments/production/{manifests,modules}
    # then run:
    puppet agent --enable
    puppet agent --test



# Requirements

* ripienar/concat >= 0.2.0
* puppetlabs/stdlib => 3.0.0

# License
Apache Licence 2.0

# Contact
Simon Piette <piette.simon@gmail.com>

# Support

Please log tickets and issues at our [Projects site](https://github.com/spiette/puppet-puppet)
