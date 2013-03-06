class jenkins::master::storeconfigs (
        $version = 'installed',
        $lts     = 0,
        $repo    = 1,
        $ui_user = '',
        $ui_pass = '') {
  class {
    'jenkins':
      version => $version,
      lts     => $lts,
      repo    => $repo;
    'jenkins::plugins':
      plugins => "$::jenkins_plugins" 
  }

  file {
    '/var/lib/jenkins/.ssh':
      ensure  => directory,
      mode    => 0600,
      owner   => 'jenkins',
      group   => 'jenkins',
      recurse => true,
  }
  exec {
    'generate_key':
      command => 'yes | ssh-keygen -t rsa -N "" -f /var/lib/jenkins/.ssh/id_rsa',
      path    => "/usr/bin:/usr/sbin:/bin",
      onlyif  => "test ! -f /var/lib/jenkins/.ssh/id_rsa || test ! -f /var/lib/jenkins/.ssh/id_rsa.pub",
  }
  $ssh_key = split($::jenkins_master_sshkey, ' ')
  # declare this master's ssh key for the slaves to collect
  @@ssh_authorized_key {
    $::hostname:
      ensure => 'present',
      user   => 'root',
      type   => 'ssh-rsa',
      key    => $ssh_key[1],
  }

  # Collect all the slaves for this master
  Jenkins_slave <<| master == $::hostname |>> {
    require  => File['/var/lib/jenkins/.ssh'],
    ui_user  => $ui_user,
    ui_pass  => $ui_pass,
    ssh_key  => '/var/lib/jenkins/.ssh/id_rsa',
    ssh_user => 'root',
  }


  Class['jenkins::repo']
  -> Class['jenkins::package']
  -> Class['jenkins::plugins']
  -> Class['jenkins::service']
  -> File['/var/lib/jenkins/.ssh']
  -> Exec['generate_key']
}
