FactoryBot.define do
  factory :widget do
    panel
    widget_type { Widget::WidgetType::BUTTON }
    x { 0 }
    y { 0 }
    w { 2 }
    h { 2 }
    color_1 { "blue" }
    color_2 { "white" }
    icon { "lightbulb" }
    sequence(:name) { |n| "Widget #{n}" }
    show_updated { false }
    show_label { true }

    trait :type_button do
      widget_type { Widget::WidgetType::BUTTON }
      program
    end

    trait :type_switch do
      widget_type { Widget::WidgetType::SWITCH }
      device
    end

    trait :type_boolean_value do
      widget_type { Widget::WidgetType::BOOLEAN_VALUE }
      device
    end

    trait :type_text_value do
      widget_type { Widget::WidgetType::TEXT_VALUE }
      device
    end

    trait :type_chart do
      widget_type { Widget::WidgetType::CHART }
      device { association :ds18b20 }
      time_window_hours { 24 }
      chart_type { Widget::ChartType::AUTO }
    end
  end
end

