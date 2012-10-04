
#
# == Paremeters:
#
#  $log_verbose - rather to log the glance api service at verbose level.
#  Optional. Default: false
#
#  $log_debug - rather to log the glance api service at debug level.
#  Optional. Default: false
#
#  $default_store - Backend used to store glance dist images.
#  Optional. Default: file
#
#  $bind_host - The address of the host to bind to.
#  Optional. Default: 0.0.0.0
#
#  $bind_port - The port the server should bind to.
#  Optional. Default: 9292
#
#  $registry_host - The address used to connecto to the registy service.
#  Optional. Default:
#
#  $registry_port - The port of the Glance registry service.
#  Optional. Default: 9191
#
#  $log_file - The path of file used for logging
#  Optional. Default: /var/log/glance/api.log
#
#
class glance::api(
  $log_verbose       = 'False',
  $log_debug         = 'False',
  $bind_host         = '0.0.0.0',
  $bind_port         = '9292',
  $backlog           = '4096',
  $workers           = $::processorcount,
  $log_file          = '/var/log/glance/api.log',
  $registry_host     = '0.0.0.0',
  $registry_port     = '9191',
  $auth_type         = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = '35357',
  $auth_protocol     = 'http',
  $auth_uri          = "http://127.0.0.1:5000/",
  $keystone_tenant   = 'admin',
  $keystone_user     = 'admin',
  $keystone_password = 'ChangeMe',
  $enabled           = true
) inherits glance {

  # used to configure concat
  require 'keystone::python'

  Package['glance'] -> Glance_api_config<||>
  Package['glance'] -> Glance_cache_config<||>
  Glance_api_config<||>   ~> Service['glance-api']
  Glance_cache_config<||> ~> Service['glance-api']
  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'root',
    mode    => '0640',
    notify  => Service['glance-api'],
    require => Class['glance'],
  }

  # basic service config
  glance_api_config {
    'DEFAULT/verbose':   value => $log_verbose;
    'DEFAULT/debug':     value => $log_debug;
    'DEFAULT/bind_host': value => $bind_host;
    'DEFAULT/bind_port': value => $bind_port;
    'DEFAULT/backlog':   value => $backlog;
    'DEFAULT/workers':   value => $workers;
    'DEFAULT/log_file':  value => $log_file;
  }

  glance_cache_config {
    'DEFAULT/verbose':   value => $log_verbose;
    'DEFAULT/debug':     value => $log_debug;
  }

  # configure api service to connect registry service
  glance_api_config {
    'DEFAULT/registry_host': value => $registry_host;
    'DEFAULT/registry_port': value => $registry_port;
  }

  glance_cache_config {
    'DEFAULT/registry_host': value => $registry_host;
    'DEFAULT/registry_port': value => $registry_port;
  }


  # auth config
  glance_api_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/protocol':          value => $protocol;
    'keystone_authtoken/auth_uri':          value => $auth_uri;
  }

  # keystone config
  if $auth_type == 'keystone' {
    glance_api_config {
      'paste_deploy/flavor':                  value => 'keystone+cachemanagement';
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $keystone_password;
    }
    glance_cache_config {
      'DEFAULT/auth_url':          value => $auth_uri;
      'DEFAULT/admin_tenant_name': value => $keystone_tenant;
      'DEFAULT/admin_user':        value => $keystone_user;
      'DEFAULT/admin_password':    value => $eystone_password;
    }
  }

  file { ['/etc/glance/glance-api.conf',
          '/etc/glance/glance-api-paste.ini',
          '/etc/glance/glance-cache.conf'
         ]:
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'glance-api':
    name       => $::glance::params::api_service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }
}
