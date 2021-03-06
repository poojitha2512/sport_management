class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :schedule, :overview, to: :read
    alias_action :update, :destroy, to: :modify
    alias_action :create_from_type, to: :create
    can :read, :all
    cannot :read, User
    cannot :read, Team, private: true
    cannot :index, User
    can :create, User
    if user.present?
      initialize_with_user(user)
    end
  end

  private

    def initialize_with_user(user)
      user_id = user.id

      # all
      can :create, :all

      # User
      can :show, User
      can [:modify, :edit_profile, :update_profile, :dashboard, :confirm_destroy, :notifications], User, id: user_id
      cannot :create, User

      # Event
      can [:create, :read, :update, :destroy], Event, owner_id: user_id
      can_join_event(user)
      can_leave_event(user)
      can :ranking, Event
      can [:schedule, :team_join], Event
      can_update_gameday(user)

      # Team
      can_crud_team(user_id)
      can_destroy_team(user)
      can_assign_ownership(user)
      can_delete_ownership(user)
      can_delete_membership(user)
      can_assign_membership_by_email(user)
      can_send_emails_to_team_members(user)

      # Match
      can_modify_match(user)
      cannot :destroy, Match

      if user.admin?
        can :manage, :all
      end

      can_confirm_scores(user)
    end

    def can_modify_match(user)
      can :modify, Match do |match|
        user.teams.where(id: match.teams).exists?
      end
    end

    def can_join_event(user)
      can :join, Event.active do |event|
        event.can_join?(user)
      end
    end

    def can_leave_event(user)
      can :leave, Event do |event|
        event.can_leave?(user)
      end
    end

    def can_update_gameday(user)
      can :update_gameday, Gameday, Gameday do |gameday|
        not (gameday.event.organizers & user.organizers).empty?
      end
    end

    def can_crud_team(user_id)
      can :read, Team, private: true, members: { id: user_id }
      can :update, Team, members: { id: user_id }
    end

    def can_destroy_team(user)
      can :destroy, Team, Team do |team|
        (team.owners.include? user) && (!team.associated_with_event?)
      end
    end

    def can_assign_membership_by_email(user)
      can :assign_membership_by_email, Team, Team do |team|
        ((team.members.include? user) || (team.owners.include? user)) && max_players_per_team_border_not_exceeded?(team, 1)
      end
    end

    def can_send_emails_to_team_members(user)
      can :send_emails_to_team_members, Team, members: { id: user.id }
    end

    def can_assign_ownership(user)
      can :assign_ownership, Team, Team do |team|
        team.owners.include? user
      end
    end

    def can_delete_membership(user)
      can :delete_membership, Team, Team do |team, team_member|
        user_id = user.id
        exist_owners_after_delete = Ability.number_of_owners_after_delete(team, team_member) > 0
        (((team.owners.include? user) && exist_owners_after_delete) || ((team.members.include? user) && (user_id == Integer(team_member)) && exist_owners_after_delete)) && min_players_per_team_border_not_exceeded?(team, 1)
      end
    end

    def can_delete_ownership(user)
      can :delete_ownership, Team, Team do |team|
        (team.owners.include? user) && team.has_multiple_owners?
      end
    end

    def self.number_of_owners_after_delete(team, team_member)
      owners = team.owners
      another_user = User.find(team_member)
      if owners.include? another_user
        owners_after_delete = owners - [another_user]
      else
        owners_after_delete = owners
      end
      owners_after_delete.length
    end

    def min_players_per_team_border_not_exceeded?(team, update_count)
      not_exceeded = true
      team.events.each do |event|
        not_exceeded = event.min_players_per_team <= team.members.count - update_count
      end
      not_exceeded
    end

    def max_players_per_team_border_not_exceeded?(team, update_count)
      not_exceeded = true
      team.events.each do |event|
        not_exceeded = event.max_players_per_team >= team.members.count + update_count
      end
      not_exceeded
    end

    def can_confirm_scores(user)
      can :confirm_scores, Match do |match|
        match.can_confirm_scores?(user)
      end
    end
end
