class CreateVisit < ActiveRecord::Migration[5.2]
  def up
    return if table_exists?(:visit)

    create_table :visit, id: false do |t|
      t.integer :visit_id, null: false, primary_key: true, autoincrement: true
      t.integer :patient_id, null: false
      t.integer :visit_type_id, null: false
      t.datetime :date_started, null: false
      t.datetime :date_stopped
      t.integer :indication_concept_id, null: true
      t.integer :location_id, null: false
      t.integer :creator, null: false
      t.datetime :date_created, null: false, default: -> { 'NOW()' }
      t.integer :changed_by
      t.datetime :date_changed
      t.boolean :voided
      t.integer :voided_by
      t.datetime :date_voided
      t.string :void_reason
      t.string :uuid, null: false, default: 'UUID()'

      t.index :date_started
      t.index :date_stopped
      t.index :patient_id
      t.index :visit_type_id
      t.index :location_id
      t.index %i[visit_type_id patient_id date_started date_stopped], name: :patient_visit

      t.foreign_key :patient, column: :patient_id, primary_key: :patient_id
      t.foreign_key :visit_type, column: :visit_type_id, primary_key: :visit_type_id
      t.foreign_key :concept, column: :indication_concept_id, primary_key: :concept_id
      t.foreign_key :users, column: :creator, primary_key: :user_id
      t.foreign_key :location, column: :location_id, primary_key: :location_id
    end
  end

  def down
    drop_table(:visit)
  end
end
