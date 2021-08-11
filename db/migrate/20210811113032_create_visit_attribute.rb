class CreateVisitAttribute < ActiveRecord::Migration[5.2]
  def up
    return if table_exists?(:visit_attribute)

    create_table :visit_attribute, id: false do |t|
      t.integer :visit_attribute_id, null: false, primary_key: true, autoincrement: true
      t.integer :visit_id
      t.integer :attribute_type_id, null: false
      t.integer :creator
      t.datetime :date_created
      t.integer :changed_by
      t.datetime :date_changed
      t.boolean :voided
      t.integer :voided_by
      t.datetime :date_voided
      t.string :void_reason
      t.string :uuid

      t.index :visit_id
      t.index :attribute_type_id

      t.foreign_key :visit_attribute_type, column: :attribute_type_id, primary_key: :visit_attribute_type_id
      t.foreign_key :visit, column: :visit_id, primary_key: :visit_id
      t.foreign_key :users, column: :creator, primary_key: :user_id
      t.foreign_key :users, column: :voided_by, primary_key: :user_id
      t.foreign_key :users, column: :changed_by, primary_key: :user_id
    end
  end

  def down
    drop_table(:visit_attribute)
  end
end
