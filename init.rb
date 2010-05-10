# Redmine initr plugin

begin
  require 'redmine'
  require File.join(File.dirname(__FILE__), 'lib','project_patch')
  require File.join(File.dirname(__FILE__), 'lib','puppet_patch')

  RAILS_DEFAULT_LOGGER.info 'Starting initr plugin for Redmine'

  # Patches to the Redmine core.
  require 'dispatcher'
  require 'project_patch'
  require 'puppet_patch'
  Dispatcher.to_prepare do
    Project.send(:include, ProjectPatch)
    User.send(:include, UserPatch)
    [
     Puppet::Rails::Host,
     Puppet::Rails::FactName,
     Puppet::Rails::FactValue,
     Puppet::Rails::Resource,
     Puppet::Rails::ParamValue,
     Puppet::Rails::ParamName,
     Puppet::Rails::ResourceTag,
     Puppet::Rails::PuppetTag,
     Puppet::Rails::SourceFile
    ].each do |c|
      c.send(:include, PuppetPatch)
    end
  end 

  Redmine::Plugin.register :initr do
    name 'initr'
    author 'Ingent'
    description 'Node management with redmine and puppet'
    version '0.0.1'
    settings :default => {
      'puppetmaster_ip' => '127.0.0.1'
    },
    :partial => '/initr/settings'

    # This plugin adds a project module
    # It can be enabled/disabled at project level (Project settings -> Modules)
    project_module :initr do
      permission :add_nodes,
        {:node => [:new,:scan_puppet_hosts]},
        :require => :member
      permission :add_templates,
        {:node => [:new_template]},
        :require => :loggedin
      permission :view_nodes,
        {:node  => [:list,:facts,:reports,:report],
         :klass => [:list]},
        :require => :member
      permission :view_own_nodes,
        {:node  => [:list,:facts,:reports,:report],
         :klass => [:list]},
        :require => :loggedin
      permission :edit_nodes,
        {:node  => [:destroy_exported_resources],
         :klass => [:create, :move, :destroy, :apply_template]},
        :require => :member
      permission :edit_own_nodes,
        {:node  => [:destroy_exported_resources],
         :klass => [:create, :move, :destroy, :apply_template]},
        :require => :loggedin
      permission :delete_nodes,
        {:node => [:destroy]},
        :require => :member
      permission :delete_own_nodes,
        {:node => [:destroy]},
        :require => :loggedin
      permission :edit_klasses,
        {:klass => [:configure]},
        :require => :member
      permission :edit_klasses_of_own_nodes,
        {},
        :require => :loggedin
    end

    # A new item is added to the project menu
    menu :project_menu, :initr, { :controller => 'node', :action => 'list' }, :caption => 'Initr'
  end
  
  # dump to a file some server info need by scripts (see initr_login)
  open("#{RAILS_ROOT}/vendor/plugins/initr/server_info.yml",'w') do |f|
    f.puts "# Autogenerated from initr/init.rb"
    f.puts "# Changes will be lost"
    f.puts "RAILS_ROOT: #{RAILS_ROOT}"
    f.puts "RAILS_ENV: #{RAILS_ENV}"
    f.puts "DOMAIN: #{Setting.plugin_initr['initr_ip']}"
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

# Needed to call node/store_report?format=yml
Mime::Type.register_alias "text/plain", :yml
