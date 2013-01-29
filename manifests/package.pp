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

# Note:  Jenkins should install java, but it doesn't.  You may have to do it on your own.
