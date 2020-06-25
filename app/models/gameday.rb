

class Gameday < ApplicationRecord
  belongs_to :event
  has_many :matches, dependent: :delete_all
  validate :end_after_starttime

  def end_after_starttime
    errors.add(:endtime, I18n.t('activerecord.validations.must_be_after', other: Gameday.human_attribute_name(:starttime))) if endtime < starttime
  end
end
