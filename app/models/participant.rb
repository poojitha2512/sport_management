
class Participant < ApplicationRecord
  belongs_to :team
  belongs_to :event

  def update_elo_for(match_result, opponent)
    opponent_rating = opponent.rating
    k_factor = event.maximum_elo_change
    expectation = 1.0 / (1.0 + (10.0**((opponent_rating - rating) / 400.0)))
    update(rating: rating + k_factor * (match_result - expectation))
    opponent.update(rating: opponent_rating + k_factor * (expectation - match_result))
  end
end
