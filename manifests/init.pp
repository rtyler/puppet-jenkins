# Parameters:
# lts = 0  (Default)
#   Use the most up to date version of jenkins
# 
#lts =1  - Use LTS verison of jenkins
#
# repo = 1 (Default)
#   install the jenkins repo.
# repo = 0  
#   Do NOT install a repo.  This means you'll manage a repo manually, outside this module.
# This is for folks that use a custom repo, or the like.


class jenkins($version = 'installed',
              $lts=0,
              $repo=1,
              $ui_user='',
              $ui_pass='') {

  class { 
    'jenkins::repo':
      lts  => $lts,
      repo => $repo,
     }
  
  class {
    'jenkins::package':
      version => $version,
  }
  
  include jenkins::service
  include jenkins::firewall
  class { 'jenkins::plugins': plugins => "$::jenkins_plugins" }

  file {
    '/var/lib/jenkins/.ssh':
      ensure => directory,
      mode => 0600,
      owner => 'jenkins',
      group => 'jenkins';

    '/var/lib/jenkins/.ssh/id_rsa':
      ensure => present,
      source => 'puppet:///modules/jenkins/id_rsa',
      owner => 'jenkins',
      group => 'jenkins',
      mode => 0600,
  }

  # Get the contents of the public key, note that 'file' adds a trailing newline
  $key_path = split($settings::modulepath, ':')
  $key_content = file("${key_path[0]}/jenkins/files/id_rsa.pub")
  $key_content_fixed = split($key_content, '\n')

  # declare this master's ssh key for the slaves to collect
  @@ssh_authorized_key {
    $::hostname:
      ensure => 'present',
      user => 'root',
      type => 'ssh-rsa',
      key => $key_content_fixed[0],
  }

  # Collect all the slaves for this master
  Jenkins_slave <<| master == $::hostname |>> {
    require => File['/var/lib/jenkins/.ssh/id_rsa'],
    ui_user => $ui_user,
    ui_pass => $ui_pass,
    ssh_key => '/var/lib/jenkins/.ssh/id_rsa',
    ssh_user => 'root',
  }


  Class['jenkins::repo']
  -> Class['jenkins::package']
  -> Class['jenkins::plugins']
  -> Class['jenkins::service']
  -> File['/var/lib/jenkins/.ssh']
  -> File['/var/lib/jenkins/.ssh/id_rsa']
}
