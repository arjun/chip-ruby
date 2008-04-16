# 
# Simple Parser for Affymetrix files in binary format
#
# See http://www.affymetrix.com/Auth/support/developer/fusion/file_formats.zip
# specifically chp-gtc.html and generic.html
#
# Author::    Arjun Sanyal (mailto:arjun.sanyal@childrens.harvard.edu)
# Copyright:: Children's Hospital Boston
# License:: GPLv2
#
#--
# Fixme
# * Change from using readers to objects (nested parent header, etc)
# * see other fixme's in code
#
# Todo
# * easy import into dbs
# * tests
# * CNCNF and LOH

# The Command Console generic data file format is a file format developed by
# Affymetrix for storing a variety of Affymetrix data and results including
# scanner acquisition data and intensity and probe array analysis results.
class CCGeneric
  def initialize(filename, max_lines)
    @debug = nil
    @verbose = nil
    
    @filename = filename
    @max_lines = max_lines
    @file_header = {}
    @generic_data_header = {}   # fixme: can be more than one header
    @generic_data_header_parameters = []
    @data_group_header = {}     # fixme: ditto
    @data_set_header = {}       # fixme: ditto
    
    puts "Filename\n--------\n#{filename}\n\n"
  end

  def read_int(f)
    f.read(4).unpack('N')[0].to_i
  end
  
  def read_char(f)
    f.read(1).unpack('C')[0].to_s
  end

  def read_string(f, wide=nil)
    n = f.read(4).unpack('N')[0]
    puts 'debug: read_string: n = ' + n.to_s if @debug
    wide ? f.read(n*2).to_s : f.read(n).unpack('a'+n.to_s).to_s
  end
  
  def read_parameter(f)
    s = read_string(f, :wide), ' ', read_string(f), ' ', read_string(f, :wide) + '\n'
  end
  
  def pretty_print_hash(h, header)
    puts header + "\n"
    header.length.times { |l| print "-" }
    puts "\n"
    h.each_pair { |key, value| puts "#{key} = #{value}" }
    puts "\n"
  end
    
  def read_header
    File.open(@filename, 'rb') do |f|
      @file_header = {  
        'magic_number' => read_char(f), 
        'version_number' => read_char(f),
        'n_data_groups' => read_int(f),
        'pos_first_data_group' => read_int(f)
      }

      pretty_print_hash(@file_header, "File Header")
      
      @generic_data_header = {
        'data_type_id' => read_string(f),
        'unique_file_id' => read_string(f),
        'created_at' => read_string(f),
        'locale' => read_string(f, :wide), # not wstring in spec?
        'n_parameters' => read_int(f)
      }

      i = 1
      @generic_data_header['n_parameters'].to_i.times do
        s = read_parameter(f)
        print i, ' ', s if @verbose
        i += 1
      end

      # fixme: there is another Generic Data Header at this point for the parent CEL file
      # starting with: affymetrix-calvin-intensity   60000027696-1179521245-0000006334-0000018467-0000000041
      pretty_print_hash(@generic_data_header, "Generic Data Header")
      puts "Hint: set 'verbose' to see all parameters\n\n" unless @verbose
    end
  end
  
  def read_data_group
    File.open(@filename, 'rb') do |f|
      f.seek(@file_header['pos_first_data_group'])

      # 31896803 = eof, therefore no next group
      @data_group_header = {
        'pos_next_data_group' => read_int(f),
        'pos_first_data_set' => read_int(f),
        'n_data_sets' => read_int(f),
        'data_set_name' => read_string(f, :wide)
      }

      pretty_print_hash(@data_group_header, 'Data Group Header')
    end
  end
  
  def read_data_set
    File.open(@filename, 'rb') do |f|
      f.seek(@data_group_header['pos_first_data_set'])

      @data_set_header = {
        'pos_first_data_element' => read_int(f),
        'pos_next_data_set' => read_int(f),
        'data_set_name' => read_string(f, :wide)
      }

      pretty_print_hash(@data_set_header, 'Data Set Header')

      # fixme: more here
      # skip to data element
      f.seek(@data_set_header['pos_first_data_element'])

      # probesetname (string, 21?), call(ubyte,1) UByte (6 = AA, 7 = BB, 8 = AB, no call otherwise),
      # confidence(float, 4), signal a(float, 4), signal b(float,4), forced call(ubyte, 1) 
      # n_rows? : 909,622
      i = 1
      while i < @max_lines+1
        n = read_int(f)
        row = f.read(n+14).unpack('a'+n.to_s+'CgggC')
        call = case row[1]
                when 6 then 'AA'
                when 7 then 'BB'
                when 8 then 'AB'
                else        'No call'
               end
  
        print i, ' ', row[0], ' '
        puts call
        i += 1
      end
    end
  end
end

# The CHP files generated by the Genotyping Console software contain SNP
# analysis results from the Birdseed and BRLMM genotyping algorithms.
class CHP < CCGeneric
  attr_reader :filename
  
  def initialize(filename, max_lines)
    super(filename, max_lines)
    load
  end

  def load
    read_header
    read_data_group
    read_data_set
  end
end

# The CEL file stores the results of the intensity calculations on the pixel
# values of the DAT file. This includes an intensity value, standard deviation
# of the intensity, the number of pixels used to calculate the intensity
# value, a flag to indicate an outlier as calculated by the algorithm and a
# user defined flag indicating the feature should be excluded from future
# analysis. The file stores the previously stated data for each feature on the
# probe array
class CEL < CCGeneric
  attr_reader :filename
  
  def initialize(filename, max_lines)
    super(filename, max_lines)
    load
  end

  def load
    read_header
    read_data_group
    read_data_set
  end
end