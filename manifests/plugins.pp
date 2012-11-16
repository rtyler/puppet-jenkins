class jenkins::plugins($plugins = ''){
  if $plugins != '' {
    Jenkins::Plugin { notify => Class[jenkins::service] }
    $plugins_list = split($plugins, ',')
    jenkins::plugin{ $plugins_list: }
  }
}
