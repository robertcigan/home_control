FactoryBot.define do
  factory :widget do
    panel
    widget_type { Widget::WidgetType::BUTTON }
    x { 0 }
    y { 0 }
    w { 2 }
    h { 2 }
    color_1 { "#007bff" }
    color_2 { "#ffffff" }
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
  end
end
