# == Class: package
#
#  Install jenkins package
#
class jenkins::package {
  package {
    'jenkins' :
      ensure => installed;
  }
}

