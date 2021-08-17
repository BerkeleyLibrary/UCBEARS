class CreateProxyBorrowerRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :proxy_borrower_requests do |t|
      t.string :faculty_name, null: false
      t.string :department
      t.string :faculty_id
      t.string :student_name
      t.string :student_dsp
      t.string :dsp_rep
      t.string :research_last, null: false
      t.string :research_first, null: false
      t.string :research_middle
      t.date :date_term
      t.integer :renewal, default: 0
      t.integer :status, default: 0
      t.timestamps null: false
    end
  end
end
