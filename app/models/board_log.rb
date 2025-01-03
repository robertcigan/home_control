class BoardLog < ApplicationRecord
  belongs_to :board

  scope :recent, -> { order("id DESC").limit(20) }

  def indication
    connected? ? "connected" : "disconnected"
  end

  def chart_data_status
    [created_at.to_s, connected? ? 1 : 0]
  end

  def chart_data_ssid
    [created_at.to_s, ssid]
  end

  def chart_data_signal_strength
    [created_at.to_s, signal_strength ? (signal_strength / 100.0) : nil]
  end

  private
  
  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end
