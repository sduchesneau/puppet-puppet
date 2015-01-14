# == Class: puppet
#
# This class will configure the puppet agent and optionnaly the puppet
# server. The puppet server will managed through puppet.
#
# === Parameters
#
# Most of the parameters have the same name than the puppet option. Look at the
# puppet documentation for more details.
#
# [*certname*]
#   Will be used by both agent and server. Defaults to `$::fqdn`. You can
#   also set alt_dns_names for the server name if you want other names.
#
# ==== Agent parameters
#
# [*server*]
#   Which server will be used by the agent. Defaults to 'puppet'
#
# ==== Master parameters
#
# [*master*]
#   Whether the puppetmaster will be installed or not.
# [*passenger*]
#   Whether the puppetmaster will be running using passenger and apache or
#   webrick.
# [*autosign*]
#   Whether the puppet master will sign automatically the agents CSR. Mostly
#   for testing, don't use that feature in production.
# [*puppetdb*]
#   Whether the puppet master will use puppetdb for storeconfigs. You need to
#   setup puppetdb separately using the puppetdb module from PuppetLabs.
# [*mount_points*]
#   Array of hashes to create fileserver mount points. Defaults to undef.
#   Keys are name, path and allow
# [*manage_service*]
#   If set to true, the puppet master service will be declared and managed
#   This may cause conflict with the puppetdb module, which also declares it.
# [*manage_passenger*]
#   If set to true, the passenger configuration will be declared and managed
#   by puppet. This is not necessary on Ubuntu because the package does it.
#   This is ignored if 'passenger' is set to false.
# [*datadir*]
#   Directory for hieradata, defaults to '/etc/puppet/hieradata'.
#   Add double-quotes in value if you want to use variables
#    (ex: '"/etc/puppet/%{::environment}/hieradata"')
#
# === Examples
#
#  class { 'puppet':
#    certname => 'somehost.somedomain.tld',
#    server   => 'puppetmaster.somedomain.tld',
#  }
#
# === Author
#
# Simon Piette <simon.piette@savoirfairelinux.com>
#
# === Copyright
#
# Copyright 2013 Simon Piette <simon.piette@savoirfairelinux.com>
# Apache 2.0 Licence
#
class puppet (
  $certname=$::fqdn,
  $server='puppet',
  $environment='production',
  $master=false,
  $agent_options=undef,
  $master_options=undef,
  $ca=true,
  $ca_server=undef,
  $passenger=false,
  $puppetdb=false,
  $manage_service=true,
  $manage_passenger=true,
  $datadir='/etc/puppet/hieradata',
  $autosign=[],
  $mount_points=undef,
) {

  include puppet::config
  anchor { 'puppet::begin': } ->
  class { 'puppet::agent':
    server      => $server,
    certname    => $certname,
    ca_server   => $ca_server,
    options     => $agent_options,
    environment => $environment,
  }

  if $master {
    class { 'puppet::master':
      ca           => $ca,
      autosign     => $autosign,
      passenger    => $passenger,
      certname     => $certname,
      puppetdb     => $puppetdb,
      mount_points => $mount_points,
      options      => $master_options,
      manage_service => $manage_service,
      manage_passenger => $manage_passenger,
      datadir => $datadir,
    } -> anchor { 'puppet::end': }
  } else {
    Class['puppet::agent'] -> anchor { 'puppet::end': }
  }
}
