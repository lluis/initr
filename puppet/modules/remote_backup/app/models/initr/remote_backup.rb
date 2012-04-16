class Initr::RemoteBackup < Initr::Klass
  unloadable

  belongs_to :remote_backup_server, :class_name => "Initr::RemoteBackupServer", :foreign_key => "klass_id"
  validates_presence_of :klass_id, :encryptkey, :keypassword, :on => :update

  self.accessors_for(%w(mailto reportsuccess includefiles excludefiles signkey encryptkey keypassword bandwidthlimit))

  def initialize(attributes=nil)
    super
    self.mailto ||= "root"
    self.reportsuccess ||= false
    self.includefiles ||= DEFAULT_INCLUDE_FILES
    self.excludefiles ||= DEFAULT_EXCLUDE_FILES
    self.bandwidthlimit ||= "0"
  end

  def parameters
    unless remote_backup_server
      raise Initr::Klass::ConfigurationError.new("Remote backup class has no remote backups server defined")
    end
    unless remote_backup_server.node
      # should never happen
      raise Initr::Klass::ConfigurationError.new("Selected remote backup server has no node associated")
    end
    params = super
    params["remotebackup"] = "remotebackup_#{node.name[0...8]}"
    params["remotebackups_path"] = remote_backup_server.remotebackups_path
    params["tags_for_sshkey"] = "#{remote_backup_server.node.name}_remote_backups_client"
    params["remote_backup_server_hash"] = remote_backup_server.node.name
    params["remote_backup_server_address"] = remote_backup_server.address
    params
  end

  def self.remote_backup_servers_for_current_user
    user_projects = User.current.projects
    Initr::RemoteBackupServer.all.collect { |rbs|
      rbs if user_projects.include? rbs.node.project
    }.compact
  end

  DEFAULT_INCLUDE_FILES = <<EOF
/var/spool/cron/crontabs
/var/backups
/etc
/root
/usr/local/*bin
/var/lib/dpkg/status*
EOF

  DEFAULT_EXCLUDE_FILES = <<EOF
/home/*/.gnupg
/home/*/.local/share/Trash
/home/*/.Trash
/home/*/.thumbnails
/home/*/.beagle
/home/*/.aMule
/home/*/gtk-gnutella-downloads
/var/cache/backupninja/duplicity
EOF

end
