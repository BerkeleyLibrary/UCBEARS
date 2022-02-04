require 'berkeley_library/alma'

module AlmaItem

  # Returns the Alma MMS ID for this item. If the record ID is a Millennium bib
  # number, this involves making an SRU request for the Alma MARC record.
  #
  # @return [BerkeleyLibrary::Alma::MMSID, nil] the Alma MMS ID, if available
  def alma_mms_id
    return @alma_mms_id if instance_variable_defined?(:@alma_mms_id)

    @alma_mms_id = find_alma_mms_id
  end

  # Returns the Alma/Primo permalink URI for this item. If the record ID is a
  # Millennium bib number, this involves making an SRU request for the Alma MARC record.
  #
  # @return [URI, nil] the URI, if available
  def alma_permalink
    return @alma_permalink if instance_variable_defined?(:@alma_permalink)

    @alma_permalink = alma_mms_id&.permalink_uri
  end

  private

  # @return [BerkeleyLibrary::Alma::MMSID, nil]
  def find_alma_mms_id
    # TODO: Cache MMS ID for Millennium records in database

    return unless (alma_record_id = BerkeleyLibrary::Alma::RecordId.parse(record_id))
    return alma_record_id if alma_record_id.respond_to?(:mms_id)
    return unless (marc_record = alma_record_id.get_marc_record)
    return unless (cf_001 = marc_record.record_id)

    canonical_record_id = BerkeleyLibrary::Alma::RecordId.parse(cf_001)
    canonical_record_id if canonical_record_id.respond_to?(:mms_id)
  end
end
