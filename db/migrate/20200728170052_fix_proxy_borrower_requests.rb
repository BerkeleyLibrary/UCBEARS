class FixProxyBorrowerRequests < ActiveRecord::Migration[5.2]
  class ProxyBorrowerRequests < ActiveRecord::Base
    # stub to ensure migration works even w/o model class
  end

  def change
    fixed_record = { faculty_name: 'Zachary Stauffer, MJ', department: 'DJOUR', faculty_id: '011916117', student_name: '', student_dsp: '', dsp_rep: '', research_last: 'Paladino', research_first: 'Jason', research_middle: 'P.', date_term: '2018-06-30 00:00:00', renewal: '0', status: '0', created_at: '2017-03-13 14:23:24' }

    rec = ProxyBorrowerRequests.find_by(date_term: '2108-06-30', faculty_id: '011916117')
    rec.update(fixed_record)

    rec.save!(validate: false)
  end
end
