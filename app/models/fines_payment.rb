# Contains a collection of Fines
#
# NOTE OF POTENTIAL CONFUSION:
# Here in Framework Land we're using the term 'Fine'
# in Alma API Land, they use the term 'Fee'
#
class FinesPayment
  include ActiveModel::Model

  attr_accessor :alma_id
  attr_accessor :pp_ref_number
  attr_accessor :fines

  validates :alma_id,
            presence: true

  def initialize(alma_id:, fine_ids: nil)
    @alma_id = alma_id
    @fines = create_fine_list fine_ids
  end

  # Return the total balance for all fines in the FinesPayment Object
  def total_amount
    fines.reduce(0.0) { |total, f| total + f.balance.to_f }
  end

  # Return jsonified array of the fine ids
  def fine_ids
    fines.map(&:id).to_json
  end

  # Credit Alma for each fee in the @fines array
  def credit
    fines.each { |f| f.credit(alma_id, pp_ref_number) }
  end

  private

  # Fetch all user's fines and filter, which is faster than fetching individual fines
  def create_fine_list(fine_ids)
    fines = Fine.where(alma_user_id: alma_id)
    return fines unless fine_ids

    fines.select { |f| fine_ids.include?(f.id) }
  end

end
