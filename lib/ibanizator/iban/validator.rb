class Ibanizator
  class Iban
    class Validator
      attr_reader :iban

      def initialize(iban)
        @iban = iban.to_s
      end

      def validate
        valid_length? && valid_checksum? && valid_account_number_checksum?
      end

      private
      def valid_length?
        return false if iban.length <= 4 # two digits for the country code and two for the checksum
        country_code = iban[0..1].upcase.to_sym
        iban.length == LENGTHS[country_code]
      end

      def valid_checksum?
        number_representation = integerize(reorder(iban))
        number_representation % 97 == 1
      end

      def reorder(iban)
        "#{iban[4..-1]}#{iban[0..3]}"
      end

      def integerize(iban)
        iban.gsub(/[A-Z]/) do |match|
          match.ord - 'A'.ord + 10
        end.to_i
      end

      def valid_account_number_checksum?
        begin
          if iban.start_with?('DE')
            case iban[4..11]
              when '66650085' # Sparkasse Pforzheim Calw
                checksum = 0
                weights = [2,3,4,5,6,7,2,3,4]              
                weights.each_with_index do |weight, index|
                  checksum += iban[20-index].to_i * weight
                end
                checksum = (11 - (checksum % 11)) % 10
                #puts "Checksum: #{checksum}, Actual value: #{iban[21].to_i}" 
                return iban[21].to_i == checksum
              when '76250000' # Sparkasse Fürth
                checksum = 0
                weights = [2,1,2,1,2,1,2,1,2]              
                weights.each_with_index do |weight, index|
                  product = iban[20-index].to_i * weight
                  product.to_s.each_char do |c|
                    checksum += c.to_i
                  end
                end
                checksum = (10 - (checksum % 10)) % 10
                return iban[21].to_i == checksum
            end
          end
          return true
        rescue Exception => e
          puts e.message
          puts e.backtrace
          return false
        end
      end
    end
  end # Iban
end # Ibanizator
