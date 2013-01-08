class jenkins::package {
  package {
    'jenkins' :
      ensure => installed;
    'java-1.6.0-openjdk':
      ensure => 'installed';
  }
}

