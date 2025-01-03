class DeviceLog < ApplicationRecord
  belongs_to :device

  scope :recent, -> { order("created_at DESC").limit(20) }

  def chart_data
    [created_at.to_s, 
      if value_boolean != nil
        value_boolean? ? 1 : 0
      elsif value_integer != nil
        device.unit.present? ? "#{value_integer}#{device.unit}" : value_integer
      elsif value_decimal != nil
        device.unit.present? ? "#{value_decimal}#{device.unit}" : value_decimal
      else
        1
      end
    ]
  end
  
  def indication
    if value_boolean != nil
      value_boolean? ? "on" : "off"
    elsif value_integer != nil
      device.unit.present? ? "#{value_integer}#{device.unit}" : value_integer
    elsif value_decimal != nil
      device.unit.present? ? "#{value_decimal}#{device.unit}" : value_decimal
    elsif value_string.present?
      device.unit.present? ? "#{value_string}#{device.unit}" : value_string
    else
      I18n.l(updated_at)
    end
  end

  private
  
  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end