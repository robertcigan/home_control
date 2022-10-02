class Widget < ApplicationRecord
  include AttributeOption
  attribute_options :widget_type, [:switch, :boolean_value, :text_value]
  
  attribute_options :color_1, [:blue, :indigo, :purple, :pink, :red, :orange, :yellow, :green, :teal, :cyan, :white, :gray, :gray_dark]
  attribute_options :color_2, [:blue, :indigo, :purple, :pink, :red, :orange, :yellow, :green, :teal, :cyan, :white, :gray, :gray_dark]
  attribute_options :icon, [:cog, :lightbulb, :toggle]

  belongs_to :panel
  belongs_to :device, optional: true
  belongs_to :program, optional: true

  validates :device, presence: { if: proc { |widget| widget.program.nil? }}

  def to_s
    name.present? ? name : (device ? device.to_s : program.to_s)
  end
end
