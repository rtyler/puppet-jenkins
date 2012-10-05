class jenkins {
  case $::operatingsystem {
    redhat,centos: {
      package {
        'jre':
            ensure => '1.7.0',
            noop   => true
      }
    }
    default: {
      package {
        'sun-java6-jre':
          ensure => 'installed'
      }
    }
  }
  include jenkins::repo
  include jenkins::package
  include jenkins::service
  include jenkins::firewall

  Class['jenkins::repo'] -> Class['jenkins::package']
  -> Class['jenkins::service']
}
# vim: ts=2 et sw=2 autoindent
