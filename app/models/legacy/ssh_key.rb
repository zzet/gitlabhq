#require "tempfile"

class Legacy::SshKey < LegacyDb
  #include Gitorious::Messaging::Publisher
  belongs_to :user

 #SSH_KEY_FORMAT = /^ssh\-[a-z0-9]{3,4} [a-z0-9\+=\/]+ SshKey:(\d+)?-User:(\d+)?$/ims.freeze

  def wrapped_key(cols=72)
    key.gsub(/(.{1,#{cols}})/, "\\1\n").strip
  end

  def to_key
    # store rails_env in development mode
    _key_rails_env = Rails.env.development? ? "RAILS_ENV=#{Rails.env} " : ""
    %Q{### START KEY #{self.id || "nil"} ###\n} +
    %Q{command="#{_key_rails_env} gitorious #{user.login}",no-port-forwarding,} +
    %Q{no-X11-forwarding,no-agent-forwarding,no-pty #{to_keyfile_format}} +
    %Q{\n### END KEY #{self.id || "nil"} ###\n}
  end

  # The internal format we use to represent the pubkey for the sshd daemon
  def to_keyfile_format
    %Q{#{self.algorithm} #{self.encoded_key} SshKey:#{self.id}-User:#{self.user_id}}
  end

  def self.add_to_authorized_keys(keydata, key_file_class=Legacy::SshKeyFile)
    key_file = key_file_class.new
    key_file.add_key(keydata)
  end

  def self.delete_from_authorized_keys(keydata, key_file_class=Legacy::SshKeyFile)
    key_file = key_file_class.new
    key_file.delete_key(keydata)
  end

  def publish_creation_message
    raise ActiveRecord::RecordInvalid.new(self) if new_record?
    options = ({:target_class => self.class.name, 
      :command => "add_to_authorized_keys", 
      :arguments => [self.to_key], 
      :target_id => self.id,
      :identifier => "ssh_key_#{id}"})

    publish("/queue/GitoriousSshKeys", options)
  end

  def publish_deletion_message
    options = ({
      :target_class => self.class.name, 
      :command => "delete_from_authorized_keys", 
      :arguments => [self.to_key],
      :identifier => "ssh_key_#{id}"})

    publish("/queue/GitoriousSshKeys", options)
  end

  def components
    key.to_s.strip.split(" ", 3)
  end

  def algorithm
    components.first
  end

  def encoded_key
    components.second
  end

  def comment
    components.last
  end

  def fingerprint
    @fingerprint ||= begin
      raw_blob = encoded_key.to_s.unpack("m*").first
      OpenSSL::Digest::MD5.hexdigest(raw_blob).scan(/../).join(":")
    end
  end

  def valid_key_using_ssh_keygen?
    temp_key = Tempfile.new("ssh_key_#{Time.now.to_i}")
    temp_key.write(self.key)
    temp_key.close
    system("ssh-keygen -l -f #{temp_key.path}")
    temp_key.delete
    return $?.success?
  end

  protected
    def lint_key!
      self.key.to_s.gsub!(/(\r|\n)*/m, "")
    end
end
