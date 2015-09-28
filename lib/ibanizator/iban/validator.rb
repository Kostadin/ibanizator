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

      def eserAccountNumber
        an = iban[8..11]
        foundDigitNotZero = false
        for i in 2..(iban.size-13)
          if ((i==2) || (i==3) || ((iban[12+i]=='0') && foundDigitNotZero) || (iban[12+i]!='0')) 
            an << iban[12+i]
            if ((i != 2) && (i != 3))
						  foundDigitNotZero = true
					  end
          end
        end
        an
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
                checksum = ((11 - (checksum % 11)) % 11) % 10
                #puts "Checksum: #{checksum}, Actual value: #{iban[21].to_i}" 
                return iban[21].to_i == checksum
              when '76250000', '33050000' # Sparkasse Fürth, Stadtsparkasse Wuppertal
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
              when '82054052' # Kreissparkasse Nordhausen
                if iban[12..13] == '00'
                  #puts "Option 1"
                  original_checksum = 0
                  checksum = 0
                  weights = [2,4,8,5,10,9,7,3,6,1,2,4]
                  old_account_number = eserAccountNumber
                  #puts old_account_number
                  an_zero_checksum = old_account_number.dup
                  checksum_index = 5
                  original_checkdigit = old_account_number[checksum_index].to_i
                  an_zero_checksum[checksum_index] = '0'                  
                  #puts an_zero_checksum
                  digit_array = []
                  an_zero_checksum.each_char do |c|
                    digit_array << c.to_i
                  end
                  checkdigit_weight = 0
                  length_diff = weights.size - digit_array.size
                  #puts "length_diff = #{length_diff}"
                  digit_array.each_with_index do |digit, index|
                    weight = weights[weights.size-length_diff-1-index]
                    product = digit * weight
                    #puts "#{weight} * #{digit} = #{product}"
                    checksum += product
                    if index==5
                      checkdigit_weight = weight          
                    end
                  end
                  #puts "checksum = #{checksum}"
                  offcut = checksum % 11
                  #puts "offcut = #{offcut}"
                  #puts "checkdigit_weight = #{checkdigit_weight}"
                  checkdigit = -1
                  for i in 0..10
                    if ((offcut + (i * checkdigit_weight) % 11) == 10)
				              checkdigit = i
                      break
			              end
                  end
                  #puts checkdigit
                  return (original_checkdigit == checkdigit)
                else
                  #puts "Option 2"
                  checksum = 0
                  weights = [2,3,4,5,6,7,8,9,3]              
                  weights.each_with_index do |weight, index|
                    product = iban[20-index].to_i * weight
                    checksum += product
                  end
                  return iban[21].to_i == (((11 - (checksum % 11)) % 11) % 10)
                end
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
