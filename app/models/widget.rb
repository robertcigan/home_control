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

  before_create :place_on_free_cell, if: :position_missing?

  # Widgets without a stored position go last, so GridStack places them into the space
  # left over and doesn't push the positioned widgets out of the fixed-height grid.
  scope :in_grid_order, -> { order(Arel.sql("widgets.y IS NULL, widgets.x IS NULL, widgets.y, widgets.x, widgets.id")) }

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

  def position_missing?
    x.nil? || y.nil? || w.nil? || h.nil?
  end

  # Puts a new widget (1×1) into the first free cell of the panel, row by row.
  # When the panel is full, the position stays empty and GridStack places the widget
  # after all the others.
  def place_on_free_cell
    columns = panel.column || 12
    rows = panel.row || 12
    placed = Widget.where(panel_id: panel_id).where.not(x: nil).where.not(y: nil).where.not(w: nil).where.not(h: nil)

    occupied = placed.pluck(:x, :y, :w, :h).flat_map do |wx, wy, ww, wh|
      (wx...(wx + ww)).to_a.product((wy...(wy + wh)).to_a)
    end.to_set

    free_cell = (0...rows).to_a.product((0...columns).to_a).find { |cy, cx| !occupied.include?([cx, cy]) }
    if free_cell
      self.y, self.x = free_cell
      self.w = 1
      self.h = 1
    end
  end

  def chart_device_must_have_logging
    if device
      if !device.log_enabled?
        errors.add(:device, "must have logging enabled to draw a chart")
      end
    end
  end
end
