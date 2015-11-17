class Initr::BindZone < ActiveRecord::Base
  unloadable
  belongs_to :bind, :class_name => "Initr::Bind"
  has_one :project, :through => :bind
  validates_presence_of :domain, :ttl
  validates_uniqueness_of :domain, :scope => 'bind_id'
  validates_numericality_of :ttl
  validates_format_of :domain, :with => /^[\w\d]+([\-\.]{1}[\w\d]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/i
  validates_format_of :domain, :with => /^[^_]+$/i
  after_save :trigger_puppetrun
  after_destroy :trigger_puppetrun
  before_save :increment_zone_serial

  # Uses package "apt-get install bind9utils"
  validate :named_checkzone

  if Initr.haltr?
    belongs_to :invoice_line
    has_one :invoice, :through => :invoice_line

    def search_invoice_lines
      like = "%#{domain}%"
      project.invoice_lines.where("invoice_lines.description like ? or invoice_lines.notes like ?",like,like)
    end

    def search_invoices
      like = "%#{domain}%"
      project.invoices.where("extra_info like ?",like)
    end
  end

  after_initialize do
    self.ttl ||= "300"

    # Search a matching invoice_line in haltr templates
    # only if not already set
    if Initr.haltr? and project and !invoice_line
      self.invoice_line = search_invoice_lines.first
      unless invoice_line
        self.invoice_line = search_invoices.first.invoice_lines.first rescue nil
      end
    end
  end

  def parameters
    {"zone"=>zone,"ttl"=>ttl,"serial"=>serial}
  end

  def increment_zone_serial
    if valid?
      # auto-update serial date (YYYYMMDD) + id 01
      if domain_changed? or ttl_changed? or zone_changed?
        self.serial="#{Time.now.strftime('%Y%m%d')}01".to_i
        unless serial_was.nil?
          while serial <= serial_was.to_i
            self.serial += 1
          end
        end
      end
    end
  end

  def <=>(oth)
    self.domain <=> oth.domain
  end

  def whois
    return @whois if @whois
    @whois = Whois.whois(domain)
  end

  def update_active_ns
    self.active_ns = `dig ns #{domain} +short +time=1 +tries=1 2&>1`.split.sort.join(' ')
  end

  def query_registry
    begin
      result = bind.nicline_client.call(
        :info_domain_bbdd,
        message: {
          input: {
            login: Redmine::Configuration['nicline_api_login'],
            password: Redmine::Configuration['nicline_api_password'],
            domain: domain,
            ipOrigen: '0.0.0.0'
          }
        }
      )
      xml = result.hash[:envelope][:body][:info_domain_bbdd_response][:return]
      doc = Nokogiri::Slop xml
      self.expires_on = doc.response.resData.exDate.content
      self.registrant = doc.response.resData.nameRegistrant.content
      logger.info "nicline: #{expires_on} - #{domain} - #{registrant}"
    rescue
      nil
    end
  end

  def named_checkzone
    checkzone = "/usr/sbin/named-checkzone"
    if File.exist?(checkzone)
      tmpfile = Tempfile.new([domain,'.conf'])
      tmpfile.write(zone_for_check)
      tmpfile.close
      out = `#{checkzone} -T ignore #{domain} #{tmpfile.path}`
      if $? != 0
        errors.add(:base, "Zone check error: #{out}")
      end
    end
  end

  private

  def trigger_puppetrun
    self.bind.trigger_puppetrun
  end

  def zone_for_check
    <<ZONE
$TTL #{ttl}
@   IN  SOA #{bind.nameservers.split.first}.  webmaster.#{domain}. (
            #{serial}
            3600
            600
            604800
            300 )
    IN  NS  #{bind.nameservers.split.first}.
#{zone}
ZONE
  end

end
