class Widget < ApplicationRecord
  include AttributeOption
  attribute_options :widget_type, [:switch, :button, :boolean_value, :text_value, :chart]
  attribute_options :chart_type, [:auto, :line, :area, :step_area, :points]

  attribute_options :color_1, [:blue, :indigo, :purple, :pink, :red, :orange, :yellow, :green, :teal, :cyan, :white, :gray, :gray_dark]
  attribute_options :color_2, [:blue, :indigo, :purple, :pink, :red, :orange, :yellow, :green, :teal, :cyan, :white, :gray, :gray_dark]
  attribute_options :icon, [:cog, :lightbulb, :toggle]

  belongs_to :panel
  belongs_to :device, optional: true
  belongs_to :program, optional: true

  validates :device, presence: { if: proc { |widget| widget.widget_type_switch? || widget.widget_type_boolean_value? || widget.widget_type_text_value? || widget.widget_type_chart? }}
  validates :program, presence: { if: proc { |widget| widget.widget_type_button? }}
  validates :time_window_hours, presence: true, numericality: { greater_than: 0 }, if: :widget_type_chart?
  validates :chart_type, presence: true, inclusion: { in: chart_types }, if: :widget_type_chart?
  validate :chart_device_must_have_logging, if: :widget_type_chart?

  def to_s
    if name.present?
      name
    else
      if device
        device.to_s
      else
        program.to_s
      end
    end
  end

  private

  def chart_device_must_have_logging
    if device
      if !device.log_enabled?
        errors.add(:device, "must have logging enabled to draw a chart")
      end
    end
  end
end
