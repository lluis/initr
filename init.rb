# Redmine initr plugin

begin
  require 'redmine'
  
  RAILS_DEFAULT_LOGGER.info 'Starting initr plugin for Redmine'

  # Patches to the Redmine core.
  require 'dispatcher'
  require 'project_patch'
  Dispatcher.to_prepare do
    Project.send(:include, ProjectPatch)
  end 

  Redmine::Plugin.register :initr do
    name 'initr'
    author 'Ingent'
    description 'Node management with redmine and puppet'
    version '0.0.1'
    settings :default => {
      'puppetmaster_ip' => '127.0.0.1',
      'autosign' => '/etc/puppet/autosign.conf',
      'puppetca' => '/usr/bin/puppetca',
      'slicehost_api_password' => '0'
    },
    :partial => 'initradmin/settings'

    # This plugin adds a project module
    # It can be enabled/disabled at project level (Project settings -> Modules)
    project_module :initr do
      permission :view_nodes,
        { :node => [:list,:facts],
          :klass => [:list]},
        :require => :member
      permission :manage_nodes,
        { :node  => [:new, :destroy],
          :base    => [:configure] },
        :require => :member
      permission :use_classes,
        { :klass   => [:create, :configure, :destroy] },
        :require => :member
      # public:
      #  * node/get_host_definition
      # admin only:
      #  * conf_names
      #  * initr_admin
      #  * klass_names
      #  * node/list when no project selected (all).
    end

    # A new item is added to the project menu
    menu :project_menu, :initr, { :controller => 'node', :action => 'list' }, :caption => 'Initr'
    menu :top_menu, :initr, { :controller => 'initradmin' }, :caption =>
      'Admin-Initr'
  end
  
  # dump to a file some server info need by scripts (see initr_login)
  open("#{RAILS_ROOT}/vendor/plugins/initr/server_info.yml",'w') do |f|
    f.puts "# Autogenerated from initr/init.rb"
    f.puts "# Changes will be lost"
    f.puts "RAILS_ROOT: #{RAILS_ROOT}"
    f.puts "RAILS_ENV: #{RAILS_ENV}"
    #TODO: can we set this automatically?
    if RAILS_ENV == 'production'
      f.puts "DOMAIN: localhost:8020"
    else
      f.puts "DOMAIN: localhost:3000"
    end
  end
  
rescue MissingSourceFile
  RAILS_DEFAULT_LOGGER.info 'Warning: not running inside Redmine'
end


# Load initr plugins when all is initialized
config.after_initialize do
  config.plugin_paths = %W( #{RAILS_ROOT}/vendor/plugins/initr/puppet/modules )
  initr_loader = Engines::Plugin::Loader.new(initializer)
  initr_loader.load_plugins
  initr_loader.add_plugin_load_paths
end

