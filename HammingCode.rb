require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class HammingCode
  attr_accessor :message_with_parity_bits, :parity_bits_mask, :parity_bits, :parity_bits_calculated
  attr_accessor :err_parity_bits_calculated, :parity_bits_generated, :err_parity_bits_generated, :message
  @message_with_parity_bits = []
  @parity_bits_mask = ""
  @parity_bits = []
  @parity_bits_calculated = []
  @err_parity_bits_calculated = []
  @parity_bits_generated = []
  @err_parity_bits_generated = []
  @message = ""

    def initialize(m)
      @message_with_parity_bits = []
      @parity_bits_mask = ""
      @parity_bits = []
      @parity_bits_calculated = []
      @err_parity_bits_calculated = []
      @parity_bits_generated = []
      @err_parity_bits_generated = []
        @message = m
    end

    def calc_check_bits_required
        m = @message.size
        r = 0
        until((m + r + 1) <= 2 ** r)
            @parity_bits.insert(r, 2 ** r)
            r += 1
        end
        print "\nparity bits: #{@parity_bits}"
    end

    def create_parity_bit_mask
      calc_check_bits_required
      print "\n-----CREATING PARITY BIT MASK-----"
      template = '-' * @parity_bits[@parity_bits.size-1]
      parity_bits_mask = template
      @parity_bits.each do |bit|
        parity_bits_mask[bit-1] = '?'
      end
      print "\nparity_bits_mask: #{parity_bits_mask}"
      @parity_bits_mask = parity_bits_mask
    end

    def embed_parity_bits
      create_parity_bit_mask
      message = @message
      embedded = []
      i=0
      while i < @parity_bits_mask.size
        if (@parity_bits_mask[i] == '-')
          embedded.insert(i, message[0])
          message = message[1...message.size]
        else
          embedded.insert(i, @parity_bits_mask[i])
        end
        i +=1
      end
        (0...message.size).each do |x|
          embedded.insert(i+x, message[x])
        end
        print "\nmessage_with_parity_bits: #{embedded}"
        @message_with_parity_bits = embedded

        return embedded
    end

    def calculate_parity_bits
      (0...@parity_bits_generated.size).each do |i|
        parityBit = @parity_bits_generated[i]
        n=0
        (0...parityBit.size).each do |j|
          if parityBit[j] == '1'
            n +=1
          end
        end
        print "\nP#{i}: #{parityBit} => #{n % 2}"
        @parity_bits_calculated.insert(i, n % 2)
      end
      print "\nparity_bits_calculated: #{@parity_bits_calculated}"
    end

    def embed_calculated_parity_bits
      calculate_parity_bits
      print "\n-----EMBEDING CALCULATED PARITY BITS-----"
      embedded = ""
      i=0
      j=0
      while i < @message_with_parity_bits.size
        if (@message_with_parity_bits[i] == '?')
          embedded += @parity_bits_calculated[j].to_s
            j += 1
        else
          embedded += @message_with_parity_bits[i]
        end
        i += 1
      end
        print "\nbefor: #{@message}"
        print "\nafter: #{embedded}"
        message_with_parity_bits_calculated = []
        (0...embedded.size).each do |x|
        	message_with_parity_bits_calculated.insert(x, embedded[x])
        end
        return message_with_parity_bits_calculated
    end

    def detect_error_bits
      print "\n-----DETECTING ERROR BITS-----"
          errBitPosition = 0
        (0...@parity_bits.size).each do |i|
            if @err_parity_bits_calculated[i] == 1
                errBitPosition += @parity_bits[i]
            end
        end
        print "\nError Bit position: #{errBitPosition}\n"
    end

    def generate_parity_bits(data, makeError = false)
        if (makeError)
            errBitPosition = Random.rand(1...data.size)
            print "\n-----HERE WE DAMAGE DATA-----\nRandom error position chosen: #{errBitPosition}"

            print "\nValue in that position: #{data[errBitPosition-1]}"
            swapped = 1 - data[errBitPosition-1].to_i
            print "\nValue in that position swapped to: #{swapped}"


            print "\nOriginal: #{data}"
            data[errBitPosition-1] = swapped.to_s

            print "\n...after: #{data}"
            print "\n-----------------------------\n"
        end

    	print "\n-----GENERATING PARITY BITS-----"
    	parity_bits_generated = []
    	(0...@parity_bits.size).each do |i|
            tmpBit = ""
            j=@parity_bits[i]-1
            pos=j
            posTo = pos+j+1
            while (pos < posTo)
                if pos >= data.size
                	break
                end
                tmpBit += data[pos]

                if pos == posTo-1
                	pos = posTo+j+1
                	posTo = pos+j+1
                else
            	    pos +=1
                end
            end
            parity_bits_generated.insert(i, tmpBit)
        end
        print parity_bits_generated
        if (makeError)
            @err_parity_bits_generated = parity_bits_generated
        else
        	@parity_bits_generated = parity_bits_generated
        end
    end

    def calculate_parity_bits_2
      print "\n-----CALCULATING PARITY BIT VALUES-----"
      (0...@err_parity_bits_generated.size).each do |i|
        parityBit = @err_parity_bits_generated[i]
        n=0
        (0...parityBit.size).each do |j|
          if parityBit[j] == '1'
            n +=1
          end
        end
        print "\nP#{i}: #{parityBit} => #{n % 2}"
        @err_parity_bits_calculated.insert(i, n % 2)
      end
    end
end

class Optparse
  CODES = %w(iso-2022-jp shift_jis euc-jp utf8 binary).freeze
  CODE_ALIASES = { 'jis' => 'iso-2022-jp', 'sjis' => 'shift_jis' }.freeze

  def self.parse(args)
    options = OpenStruct.new

    options.m = '01001101'

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: testRun.rb [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-m', '--message [string]',
              'Message') do |m|
        options.m = m
      end

      opts.separator ''
      opts.separator 'Common options:'
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end
end

options = Optparse.parse(ARGV)
hamming_code = HammingCode.new(options.m)
# Add parity bit mask to message
message_with_parity_bits = hamming_code.embed_parity_bits
hamming_code.generate_parity_bits(message_with_parity_bits)
# Add actual parity bits to message
message_with_parity_bits_calculated = hamming_code.embed_calculated_parity_bits
# Damage message and generate damaged message parity bits
hamming_code.generate_parity_bits(message_with_parity_bits_calculated, true)
hamming_code.calculate_parity_bits_2
# Detect error bit location
hamming_code.detect_error_bits
