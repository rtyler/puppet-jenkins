class jenkins::slave::storeconfigs (
    $master,
    $ensure    = 'enabled',
    $num_exec  = 2,
    $desc      = 'Added by puppet',
    $labels    = '',
    $remote_fs = '/var/lib/jenkins') {

  package {
    'java-1.6.0-openjdk':
      ensure => 'installed'
  }

  @@jenkins_slave {
    "$::hostname":
      ensure    => $ensure,
      master    => $master,
      num_exec  => $num_exec,
      desc      => $desc,
      remote_fs => $remote_fs,
      labels    => $labels,
  }

  file {
    $remote_fs:
      ensure => directory,
      mode   => 0755,
      owner  => 'jenkins',
      group  => 'jenkins',
  }

  if (!defined(Group['jenkins'])) {
    group {
      'jenkins' :
        ensure => present;
    }
  }

  if (!defined(User['jenkins'])) {
    user {
      'jenkins' :
        ensure => present;
    }
  }

  Ssh_authorized_key <<| title == $master |>>
}
