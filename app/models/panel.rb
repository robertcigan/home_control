class Panel < ApplicationRecord
  include WebsocketPushChange
  
  has_many :widgets, dependent: :destroy
  validates :name, presence: true
  accepts_nested_attributes_for :widgets, reject_if: :all_blank, allow_destroy: true

  def to_s
    name
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end