class Ibanizator
  class Iban
    module ExtendedData
      class FI
        attr_reader :iban
        include Equalizer.new(:iban)
        include Adamantium

        def initialize(iban)
          raise Invalid, "can't compute extended data on invalid iban" unless iban.valid?
          @iban = iban
        end

        def bank_code
          iban.to_s[4..9]
        end
        memoize :bank_code

        def account_number
          iban.to_s[10..-1].gsub(/\A0+/,"")
        end
        memoize :account_number

        def bic
          Ibanizator.bank_db.bank_by_bank_code(bank_code).bic
        end
        memoize :bic
      end
    end # ExtendedData
  end # Iban
end # Ibanizator
