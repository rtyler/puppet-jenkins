# == Class: config
#
#  configure jenkins package
#
class jenkins::config (
  $home='/var/lib/jenkins',
  $user='jenkins',
  $port='8080'
)
{

  file { '/etc/sysconfig/jenkins':
    content => template('jenkins/jenkins.erb'),
    owner   => 'root',
    group   => 'root',
    require => Package['jenkins'],
    notify  => Service['jenkins']
  }

}
