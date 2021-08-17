class ChangeStackPassDenialReasonType < ActiveRecord::Migration[5.2]
  def change
    change_column(:stack_pass_forms, :denial_reason, :string)
  end
end
