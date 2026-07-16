class DeviceLog < ApplicationRecord
  include ChartSeries

  belongs_to :device

  scope :recent, -> { order("created_at DESC").limit(20) }

  def self.chart_series(device, min, max, cap: MAX_CHART_POINTS)
    attribute = device.value_attribute
    if attribute.nil?
      []
    else
      build_chart_series(device, min, max, attribute, cap)
    end
  end

  def chart_data
    [
      created_at.to_s,
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

  def numeric_chart_value
    if value_boolean != nil
      value_boolean? ? 1 : 0
    elsif value_integer != nil
      value_integer
    elsif value_decimal != nil
      value_decimal
    else
      1
    end
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

  class << self
    private

    def build_chart_series(device, min, max, attribute, cap)
      scope = chart_window_scope(:device_id, device.id, min, max)
      count = scope.count

      if attribute == :value_boolean
        boolean_chart_series(scope)
      elsif attribute == :value_integer || attribute == :value_decimal
        numeric_chart_series(scope, device, min, max, attribute, count, cap)
      else
        scope.map do |log|
          [log.created_at.to_s, 1]
        end
      end
    end

    def boolean_chart_series(scope)
      # Keep every state change — sampling would drop short on/off pulses.
      scope.map do |log|
        [log.created_at.to_s, log.value_boolean? ? 1 : 0]
      end
    end

    def numeric_chart_series(scope, device, min, max, attribute, count, cap)
      if count > cap
        bucket_average_series(
          owner_id: device.id,
          owner_column: :device_id,
          value_column: attribute,
          min: min,
          max: max,
          cap: cap
        )
      else
        scope.map do |log|
          [log.created_at.to_s, log.public_send(attribute)]
        end
      end
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
