class CreateVisitAttributeType < ActiveRecord::Migration[5.2]
  def up
    return if table_exists?(:visit_attribute_type)

    create_table :visit_attribute_type, id: false do |t|
      t.integer :visit_attribute_type_id, primary_key: true, null: false, autoincrement: true
      t.string :name, limit: 255, null: false
      t.string :description, limit: 1024
      t.string :datatype, limit: 255
      t.text :datatype_config, limit: 65_535
      t.string :preferred_handler, limit: 255
      t.text :handler_config, limit: 65_535
      t.integer :min_occurs
      t.integer :max_occurs
      t.integer :creator, null: false
      t.datetime :date_created, null: false, default: -> { 'NOW()' }
      t.integer :changed_by
      t.datetime :date_changed
      t.boolean :retired
      t.integer :retired_by
      t.datetime :date_retired
      t.string :retire_reason
      t.string :uuid, null: false, limit: 38, default: 'UUID()'

      t.index :name
      t.foreign_key :users, column: :creator, primary_key: :user_id
      t.foreign_key :users, column: :retired_by, primary_key: :user_id
      t.foreign_key :users, column: :changed_by, primary_key: :user_id
    end
  end

  def down
    drop_table(:visit_attribute_type)
  end
end
