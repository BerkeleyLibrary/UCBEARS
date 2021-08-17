require 'webmock'

def stub_patron_dump(patron_id, status: 200, body: nil)
  escaped_id      = Patron::Dump.escape_patron_id(patron_id)
  patron_dump_url = "https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/#{escaped_id}/dump"
  stub_request(:get, patron_dump_url).to_return(
    status: status,
    body: body || begin
      body_file = "spec/data/patrons/#{escaped_id}.txt"
      raise IOError, "No such file: #{body_file}" unless File.file?(body_file)

      File.new(body_file)
    end
  )
end

def all_patron_ids
  Dir.entries('spec/data/patrons').select { |f| f =~ /[0-9]+\.txt/ }.map { |f| f.match(/([0-9]+)/)[0] }
end

# Extension methods for Patron module and Patron::Type class, used only in test
module Patron

  # Sample IDs corresponding to spec/data/calnet and spec/data/patrons
  SAMPLE_IDS = {
    Patron::Type::UNDERGRAD => '99999997',
    Patron::Type::UNDERGRAD_SLE => '3032640236',
    Patron::Type::GRAD_STUDENT => '18273645',
    Patron::Type::FACULTY => '12345678',
    Patron::Type::MANAGER => '5551213',
    Patron::Type::LIBRARY_STAFF => '013191304',
    Patron::Type::STAFF => '5551212',
    Patron::Type::POST_DOC => '99999891',
    Patron::Type::LBNL_ACADEMIC_STAFF => '012065197',
    Patron::Type::VISITING_SCHOLAR => '87651234'
  }.freeze

  FRAMEWORK_ADMIN_ID = '013191304'.freeze

  class Type
    class << self
      def name_of(code)
        const = Type.constants.find { |c| Type.const_get(c) == code }
        const.to_s if const
      end

      def all
        Type.constants.map { |const| Type.const_get(const) }
      end

      def sample_id_for(code)
        sample_id = Patron::SAMPLE_IDS[code]
        raise ArgumentError, "No sample ID for patron type #{name_of(code)}" unless sample_id

        sample_id
      end
    end
  end
end
