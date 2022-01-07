# Ensure migration can run without error even if we delete/rename the models
class Item < ActiveRecord::Base; end unless defined?(Item)
class Term < ActiveRecord::Base; end unless defined?(Term)

# Temp model class for bulk operations
class ItemsTerm < ActiveRecord::Base; end unless defined?(ItemsTerm)

class AddSpringTermToDec2ItemList < ActiveRecord::Migration[6.1]
  DEC_2_ITEM_DIRS = %w[
    991004442059706532_C097717392
    991005774859706532_C111565200
    991006481349706532_C067842870
    991009679929706532_C113165615
    991010244139706532_C092845990
    991010391809706532_C104852903
    991011693289706532_C106048062
    991011957869706532_C068441125
    991013037299706532_C122721407
    991031702789706532_C073941219
    991036422109706532_C113319468
    991040031399706532_C118398261
    991040038969706532_C119762347
    991046977259706532_C119772844
    991048516179706532_C117987888
    991048686749706532_C078355898
    991049106039706532_C116293240
    991049162109706532_C122721063
    991049737639706532_C004362692
    991050531759706532_C122578339
    991050646649706532_C078357911
    991050859039706532_C122139175
    991051333839706532_C116377829
    991051353589706532_C116377643
    991052080309706532_C122557067
    991053505419706532_C061560752
    991054801499706532_C122449820
    991054822289706532_C122449583
    991054852699706532_C122448516
    991054859309706532_C122494811
    991055118969706532_C122449741
    991055967529706532_C122697633
    991064235719706532_C068919603
    991075154189706532_C089223069
    991078304779706532_C067861560
    991078451879706532_C116176184
    991080045779706532_C105340754
    991080911379706532_C110159368
    991085892689706532_C122697536
    991085893988606532_C122697624
    991085893989006532_C122697509
    991085894189606532_C122721142
    B135491460_C106083325
    B149214868_C046278538
    B150375141_C088842275
    B165164542_C119012063
    B177142832_C099784251
    B222475535_C122578010
    B223226981_C114594979
    B24912416_C121029917
    B254072677_C122447497
    B259281475_C122678800
    b120383780_C106023402
    b126490909_B5605438
    b127102036_C096248480
    b127181830_C106036798
    b130741966_B000244546
    b13680878_C122550856
    b13680878_C122550865
    b141656554_C058485770
    b15727973x_B4966135
    b15727973x_B4966136
    b16128088_C106388245
    b183314700_C106108003
    b221264814_C122540058
    b246912194_C121191639
    b251098734_C118842484
    b257125759_C122550874
    b257125760_C122551151
    b25788672_C122449547
    b257892400_C122540155
    b257896314_C122540067
    b258276058_C123401551
    b258384219_C122649923
    b258384220_C122649914
    b258384955_C119045070
    b259228138_C119045104
    b259380635_C122678466
    b259380787_C122157533
  ].freeze

  def up
    return unless (term_id = term_id_spring_2022)

    item_ids = Item.where(directory: DEC_2_ITEM_DIRS).pluck(:id)
    return if item_ids.empty?

    values = item_ids.map { |item_id| { item_id: item_id, term_id: term_id } }
    ItemsTerm.insert_all(values)
  end

  def down
    return unless (term_id = term_id_spring_2022)

    item_ids = Item.where(directory: DEC_2_ITEM_DIRS).pluck(:id)
    return if item_ids.empty?

    ItemsTerm.where(item_id: item_ids, term_id: term_id).delete_all
  end

  private

  def term_id_spring_2022
    return unless (term = Term.find_by(name: 'Spring 2022'))

    term.id
  end
end
