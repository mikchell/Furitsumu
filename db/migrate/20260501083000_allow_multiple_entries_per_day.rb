class AllowMultipleEntriesPerDay < ActiveRecord::Migration[7.1]
  def change
    remove_index :entries, name: "index_entries_on_user_id_and_recorded_on"
    add_index :entries, [ :user_id, :recorded_on ], unique: false
  end
end
