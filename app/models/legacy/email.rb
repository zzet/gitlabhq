class Legacy::Email < LegacyDb
  belongs_to :user

  state_machine :aasm_state, :initial => :pending do
    after_transition :on => :confirm do |email, transition|
      email.confirmation_code = nil
    end
    state :pending
    state :confirmed
    event :confirm do
      transition :pending => :confirmed
    end
  end

  scope :in_state, lambda {|*states| {:conditions => {:aasm_state => states}}}

  def self.find_confirmed_by_address(addr)
    with_aasm_state(:confirmed).first(:conditions => {:address => addr})
  end

  protected
    def send_confirmation_email
    end

    def set_confirmation_code
    end
end
