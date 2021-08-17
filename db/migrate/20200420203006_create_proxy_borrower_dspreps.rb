class CreateProxyBorrowerDspreps < ActiveRecord::Migration[5.2]
  def change
    create_table :proxy_borrower_dspreps do |t|
      t.string :dsp_rep_name, null: false
    end
  end
end
