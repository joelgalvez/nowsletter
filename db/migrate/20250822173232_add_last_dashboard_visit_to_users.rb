class AddLastDashboardVisitToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_dashboard_visit, :datetime
  end
end
