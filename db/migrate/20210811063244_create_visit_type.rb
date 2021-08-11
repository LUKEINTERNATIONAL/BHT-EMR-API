class CreateVisitType < ActiveRecord::Migration[5.2]
  def up
    return if table_exists?(:visit_type)

    create_table :visit_type, id: false do |t|
      t.integer :visit_type_id, null: false, primary_key: true, autoincrement: true
      t.string :name, null: false, limit: 255
      t.string :description, limit: 1024
      t.integer :creator, null: false
      t.datetime :date_created, null: false, default: -> { 'NOW()' }
      t.integer :changed_by
      t.datetime :date_changed
      t.boolean :retired
      t.integer :retired_by
      t.datetime :date_retired
      t.string :retire_reason, limit: 255
      t.string :uuid, null: false, default: 'UUID()', limit: 38

      t.index :name
      t.foreign_key :users, column: :creator, primary_key: :user_id
      t.foreign_key :users, column: :retired_by, primary_key: :user_id
      t.foreign_key :users, column: :changed_by, primary_key: :user_id
    end
  end

  def down
    drop_table(:visit_type)
  end
end
