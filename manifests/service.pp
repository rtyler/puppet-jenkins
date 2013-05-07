# == Class: service
#
#  Init jenkins service
#
class jenkins::service {
  service { 'jenkins':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}

