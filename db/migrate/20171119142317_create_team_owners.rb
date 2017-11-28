class CreateTeamOwners < ActiveRecord::Migration[5.1]
  def change
    create_join_table :teams, :users, table_name: :team_owners do |t|
      t.index [:user_id, :user_id]
    end
  end
end
