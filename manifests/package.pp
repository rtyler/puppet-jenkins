class jenkins::package ($version = 'installed') {

  case $::osfamily {
    'RedHat': {
      $java_pkg_name = 'java-1.6.0-openjdk'
    }
    'Debian': {
      $java_pkg_name = 'openjdk-6-jre'
    }
    default: {
      fail("Unsupported OS family: $::osfamily")
    }
  }

  package {
    'jenkins' :
      ensure => $version;
    $java_pkg_name:
      ensure => 'installed';
  }
}

