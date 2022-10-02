class Panel < ApplicationRecord
  include WebsocketPushChange
  
  has_many :widgets, dependent: :destroy
  validates :name, presence: true
  accepts_nested_attributes_for :widgets, reject_if: :all_blank, allow_destroy: true

  def to_s
    name
  end
end