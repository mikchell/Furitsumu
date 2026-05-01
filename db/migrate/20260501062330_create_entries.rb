class CreateEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :recorded_on, null: false
      t.integer :duration_seconds
      t.text :transcript
      t.string :summary
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :entries, [ :user_id, :recorded_on ], unique: true
  end
end
