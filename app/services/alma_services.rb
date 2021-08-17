module AlmaServices
  class Fines
    def self.fetch_all(alma_user_id)
      req = "#{Config.alma_api_url}users/#{alma_user_id}/fees?apikey=#{Config.alma_api_key}"
      res = Faraday.get(req, {}, { 'Accept' => 'application/json' })
      raise ActiveRecord::RecordNotFound, 'No fees could be found.' unless res.status == 200

      JSON.parse(res.body)
    end

    def self.credit(alma_user_id, pp_ref_number, fine)
      # If you pay the full amount owed for a fee, it automatically changes the status to "CLOSED"
      req = "#{Config.alma_api_url}users/#{alma_user_id}/fees/#{fine.id}?apikey=#{Config.alma_api_key}&op=pay&amount=#{fine.balance}
      &method=ONLINE&external_transaction_id=#{pp_ref_number}"

      res = Faraday.post(req, {}, { 'Accept' => 'application/json' })
      raise ActiveRecord::RecordNotFound, "Failed to credit fee #{fee_id}" unless res.status == 200
    end
  end

  class Config
    def self.alma_api_url
      Rails.application.config.alma_api_url
    end

    def self.alma_api_key
      Rails.application.config.alma_api_key
    end
  end
end
