class jenkins::master::swarmplugin (
        $version = 'installed',
        $lts     = 0,
        $repo    = 1) {
  class {
    'jenkins':
      version => $version,
      lts     => $lts,
      repo    => $repo;
  }

  jenkins::plugin {'swarm': }

  Class['jenkins::repo']
  -> Class['jenkins::package']
  -> Jenkins::plugin['swarm']
  -> Class['jenkins::service']
}
