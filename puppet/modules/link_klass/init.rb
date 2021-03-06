require 'redmine'

require File.join(File.dirname(__FILE__), 'rails_lib','klass_patch')

Rails.configuration.to_prepare do
  Initr::Klass.send(:include,KlassPatch)
end

Rails.logger.info 'Starting link_klass plugin for Initr'

Initr::Plugin.register :link_klass do
  name 'link_klass'
  author 'Ingent'
  description 'LinkKlass plugin for initr'
  version '0.0.1'
  project_module :initr do
    add_permission :edit_klasses, { :link_klass => [:new,:create,:configure] }
  end
  klasses 'link_klass' => {:description => 'use a class from other node, link it', :unique => false}
end

::I18n.load_path += Dir.glob(File.join("#{File.dirname(__FILE__)}", 'config', 'locales', '*.yml'))
