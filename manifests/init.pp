
class jenkins {
  package {
    'java-1.6.0-openjdk':
        ensure => 'installed'
  }
  include jenkins::repo
  include jenkins::package
  include jenkins::service
  include jenkins::firewall
  class{ 'jenkins::plugins': plugins => "$::jenkins_plugins" }


  Package['java-1.6.0-openjdk']
  -> Class['jenkins::repo']
  -> Class['jenkins::package']
  -> Class['jenkins::plugins']
  -> Class['jenkins::service']
}
# vim: ts=2 et sw=2 autoindent
