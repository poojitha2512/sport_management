
class Rankinglist < Event
  validates :deadline, :startdate, :enddate, presence: false
  validates :initial_value, presence: true

  enum game_mode: [:elo]

  def update_rankings(match)
    if (elo?)
      match.apply_elo
    end
  end

  def can_leave?(user)
    has_participant? user
  end

  before_validation do
    self.player_type = Event.player_types[:single]
    self.min_players_per_team = 1
    self.max_players_per_team = 1
  end
end
