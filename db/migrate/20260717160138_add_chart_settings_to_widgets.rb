class AddChartSettingsToWidgets < ActiveRecord::Migration[8.1]
  def change
    add_column :widgets, :time_window_hours, :decimal, precision: 10, scale: 3, default: 24, null: false
    add_column :widgets, :chart_type, :string, default: "auto", null: false
  end
end
