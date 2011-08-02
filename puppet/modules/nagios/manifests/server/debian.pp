class nagios::server::debian inherits nagios::server::common {

  package {
    "nagios3":
      ensure => installed,
      alias => nagios;
  }
  service {
    "nagios3":
      enable => true,
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      alias => nagios;
    "nsca":
      enable => true,
      ensure => running,
      hasstatus => false,
      hasrestart => true;
  }
  file {
    "/etc/nagios3/htpasswd.users":
      content => template("nagios/htpasswd.users.erb"),
      owner => root,
      group => $httpd_user,
      mode => 0640,
      require => Package["nagios3"];
    # needed for nagios external command (/usr/share/doc/nagios3/README.Debian)
    "/var/lib/nagios3":
      owner => nagios,
      group => nagios,
      mode => 0751,
      require => Package["nagios3"];
    # needed for nagios external command (/usr/share/doc/nagios3/README.Debian)
    "/var/lib/nagios3/rw":
      owner => nagios,
      group => www-data,
      mode => 2710,
      require => Package["nagios3"];
    "/etc/nagios3/nagios.cfg":
      content => template("nagios/nagios.cfg.erb"),
      notify => Service["nagios3"],
      require => Package["nagios3"];
    # puppet needs nagios conf in default dir to purge it (architectural limitation)
    "/etc/nagios3/conf.d":
      ensure => "/etc/nagios",
      backup => false,
      force => true,
      require => File["/etc/nagios"];
    "/etc/nagios3/commands.cfg":
      content => template("nagios/commands.cfg.erb"),
      require => Package["nagios3"],
      notify => Service["nagios"];
    "/etc/nsca.cfg":
      owner => nagios,
      group => $nagios_group,
      mode => 640,
      content => template("nagios/nsca.cfg.erb"),
      require => [Package["nsca"], Package["nagios"]],
      notify => Service["nsca"];
    "/etc/apache2/conf.d/nagios3.conf":
      source => "puppet:///modules/nagios/apache.conf";
    # Replace init.d script to check config before restart nagios daemon
    "/etc/init.d/nagios3":
      owner => root,
      group => root,
      mode => 755,
      source => "puppet:///modules/nagios/nagios_init_script_debian";
  }
}

