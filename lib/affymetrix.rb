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
#
# Todo
# * tests
# * CNCNF and LOH

# The Command Console generic data file format is a file format developed by
# Affymetrix for storing a variety of Affymetrix data and results including
# scanner acquisition data and intensity and probe array analysis results.
#
# Each subclass of CCGeneric must impliment three functions
#
# * read_data_row(f, data_set_header=nil) - f: file object to read, data_set_header (optional)
# * print_data_row(h, i) - h: hash of row, i: index
# * write_data_row(h, csv) - h: hash of row, csv: output file object
#

require "csv"
require "yaml"

class CCGeneric
  VALUE_TYPES = [:byte, :ubyte, :short, :ushort, :int, :uint, :float, :string, :wstring]

  # Init the Command Console Generic date file (parent of all other files)
  # params:
  # - filename (string, required)
  # - maxlines (int, defaults to 100)
  # - verbosity (can be :normal, :verbose, :debug, :quiet)
  def initialize(params)
    if not defined? params[:filename]
      raise "Filename required. Exiting."
    end
    
    @filename = params[:filename]
    @filesize = File.size(@filename)
    
    if not defined? params[:maxlines]
      puts "Info: maxlines set to 1M"
    end 
    
    @maxlines = params[:maxlines] || 1000000
    @verbosity = params[:verbosity] || :normal

    @file_header = {}
    @generic_data_headers = []
    @generic_data_header_parameters = []
    @data_groups = []
    @data_sets = []

    puts "\nFilename\n--------\n#{@filename}\n\n" unless @verbosity == :quiet
  end

  #--
  # methods for reading raw bytes
  #
  def read_ubyte(f)
    f.read(1).unpack("C")
  end

  def read_float(f)
    f.read(4).unpack("g")
  end

  def read_ushort(f)
    f.read(2).unpack("v")
  end

  def read_int(f)
    f.read(4).unpack("N")[0].to_i
  end
  
  def read_char(f)
    f.read(1).unpack("C")[0].to_s
  end

  # Note: "wide" is UTF-16BE (for big/network-endian, no byte-order-mark)
  # e.g. char 'z' encoded to bytes as '00 7A' or printed (using "z".inspect) as "\000z"
  #
  # This method casts wide strings to normal strings
  def read_string(f, wide=nil)
    n = f.read(4).unpack("N")[0]
    
    if wide then
      s = f.read(n*2).to_s
      s2 = ""
      s.each_byte do |c|
        s2 << c unless c == 0
      end
      return s2
    else
      f.read(n).unpack("A"+n.to_s).to_s
    end
  end
  
  def read_parameter(f)
    [read_string(f, :wide), read_string(f), read_string(f, :wide)]
  end

  def read_column(f)
    [read_string(f, :wide), read_char(f), read_int(f)]
  end

  #--
  # methods for printing
  #

  def pretty_print_headline(header)
    puts header, "-" * header.length unless @verbosity == :quiet
  end
  
  def pretty_print_parameters(h, header)
    return if @verbosity == :quiet or @verbosity == :normal
    pretty_print_headline header
    h[:parameters].each do |p|
      puts "#{p[0]} = #{p[1]} (#{p[2]})"
    end
    puts "\n"
  end

  def pretty_print_columns(columns, header)
    return if @verbosity == :quiet
    pretty_print_headline header
    columns.each do |c|
      puts "#{c[0]} (type: #{VALUE_TYPES[c[1].to_i]}, size: #{c[2]})"
    end
    puts "\n"
  end

  def pretty_print_hash(h, header)
    return if @verbosity == :quiet
    pretty_print_headline header
    h.each_pair { |key, value| puts "#{key} = #{value}" }
    puts "\n"
  end

  #--
  # methods for file headers
  # 
  
  def read_file_header(f)
    @file_header = {  
      :magic_number => read_char(f), 
      :version_number => read_char(f),
      :n_data_groups => read_int(f),
      :pos_first_data_group => read_int(f)
    }
  end
  
  # Note: locale is a wide string, but not specified as such in spec
  def read_generic_data_headers(f)
    h = {
      :data_type_id => read_string(f),
      :unique_file_id => read_string(f),
      :created_at => read_string(f),
      :locale => read_string(f, :wide),
      :n_parameters => read_int(f),
      :parameters => [],
      :n_parent_file_headers => nil,
      :parent_file_headers => []
    }
    
    h[:n_parameters].to_i.times do
      h[:parameters] << read_parameter(f)
    end

    h[:n_parent_file_headers] = read_int(f)

    h[:n_parent_file_headers].times do |n|
      read_generic_data_headers(f)
    end

    @generic_data_headers << h
  end
    
  def read_header
    File.open(@filename, "rb") do |f|
      read_file_header f
      read_generic_data_headers f
    end
  end

  def print_header
    File.open(@filename, "rb") do |f|
      pretty_print_hash @file_header, "File Header"
      puts "Hint: set 'verbosity' to see all parameters and parent file headers\n\n" if @verbosity == :normal
      pretty_print_hash @generic_data_headers[0], "Generic Data Header (w/o Parent File Headers)"
      pretty_print_parameters @generic_data_headers[0], "Parameters"
    end
  end

  #--
  # methods for data
  # 
  
  def read_data_groups(pos = @file_header[:pos_first_data_group])
    File.open @filename, "rb" do |f|
      f.seek pos

      h = {
        :pos_next_data_group => read_int(f),
        :pos_first_data_set => read_int(f),
        :n_data_sets => read_int(f),
        :data_group_name => read_string(f, :wide)
      }

      if h[:pos_next_data_group] < @filesize and h[:pos_next_data_group] != 0 then
        read_data_groups h[:pos_next_data_group]
      end
      
      @data_groups << h
    end
  end

  def print_data_groups()
    @data_groups.each do |h|
      pretty_print_hash h, "Data Group Header (#{@data_groups.length})"
    end
  end
  
  def read_data_sets
    File.open(@filename, "rb") do |f|
      @data_groups.each do |data_group|
        
        f.seek(data_group[:pos_first_data_set])

        h = {
          :pos_first_data_element => read_int(f),
          :pos_next_data_set => read_int(f),
          :data_set_name => read_string(f, :wide),
          :n_parameters => read_int(f),
          :parameters => [],
          :n_columns => 0,
          :columns => [],
          :rows  => []
        }

        h[:n_parameters].to_i.times do
          h[:parameters] << read_parameter(f)
        end

        h[:n_columns] = read_int(f)

        h[:n_columns].to_i.times do
          h[:columns] << read_column(f)
        end
        
        @data_sets << h
        
        f.seek(h[:pos_first_data_element])

        i = 1
        while f.tell < @filesize
          puts "f.tell is #{f.tell} / #{h['data_set_name']}" if @verbosity == :debug
          
          # call the child class reading method
          h[:rows] << read_data_row(f, h)

          if i == @maxlines then break
          else i += 1
          end
        end
      end
    end
  end

  def print_data_sets
    @data_sets.each_with_index do |h, i|
      # pretty_print_hash(h, "Data Set Header (#{i})")
      pretty_print_parameters(h, "Parameters (#{i})")
      pretty_print_columns(h[:columns], "Columns (#{i})")

      h[:rows].each_with_index do |row, i|
        print_data_row(row, i) unless @verbosity == :quiet
      end
    end
  end

  def write_data_sets(h)
    if not defined? h[:filename]
      raise "Filename required. Exiting."
    end
    
    if not defined? h[:format]
      puts "Warning: format set to csv"
    end 
    
    filename = h[:filename]
    format = h[:format] || "csv"
    
    pretty_print_headline "\nWriting to #{filename}"

    outfile = File.open(filename, "wb")

    CSV::Writer.generate outfile do |csv|
      @data_sets.each do |e|
        e[:rows].each do |e|
          write_data_row(e, csv)
        end
      end
    end
  end
end

# - Subclasses

# Genotyping Console files with SNP analysis results from the Birdseed and BRLMM genotyping algorithms
# and SNP, CNCHP, LOHCHP types
class GenotypingCHP < CCGeneric
  def initialize(args)
    super(args)
    read_header
    read_data_groups
    read_data_sets
  end

  private
  
  # fixme: use contrast and strength for BRLMM algo
  # spec bug: "forced call" after confidence in spec, but after signal_b in file
  def read_data_row(f, data_set_header)
    h = {
      :probe_set_name  => read_string(f),
      :call  => read_char(f),
      :confidence  => read_float(f),
      :signal_a  => read_float(f),
      :signal_b  => read_float(f),
      :forced_call  => read_char(f)
    }

    h[:call] = case h[:call]
      when "6" then "AA"
      when "7" then "BB"
      when "8" then "AB"
      else "No call"
    end
    
    return h
  end
  
  def print_data_row(h, i)
    if @verbosity == :normal then
      puts "#{i} #{h[:probe_set_name]} #{h[:call]}"
    else 
      pretty_print_hash(h, "Row #{i}")
    end
  end

  def write_data_row(h, csv)
    csv << [h[:probe_set_name], h[:call]]
  end
end

# Expression Console files with probe set analysis results from the MAS5, PLIER, RMA and DABG algorithms
#
# Fixme: need to use the correct method to read row based on type and for diff algos
class ExpressionCHP < CCGeneric
  def initialize(args)
    super(args)
    read_header
    read_data_groups
    read_data_sets
  end

  private

  # Expression Console (MAS5)
  def read_background_zone_data_row(f)
    h = {
      :center_x => read_float(f),
      :center_y => read_float(f),
      :background => read_float(f),
      :smooth_factor => read_float(f)
    }
  end

  def read_expression_results_row(f)
    h = {
      :probe_set_name => read_string(f, :wide),
      :detection => read_ubyte(f),
      :detection_p_value  => read_float(f),
      :signal => read_float(f),
      :n_pairs => read_ushort(f),
      :n_pairs_used => read_ushort(f)
    }
  end

  def read_data_row(f, data_set_header)
    if data_set_header[:data_set_name] == "Background Zone Data"  then
      read_background_zone_data_row(f)
    elsif data_set_header[:data_set_name] == "Expression Results" then
      read_expression_results_row(f)
    else
      raise "Bad :data_set_name #{data_set_header[:data_set_name]}"
    end
  end

  def print_data_row(h, i)
    pretty_print_hash(h, "Row #{i}")
  end

  def write_data_row(h, csv)
    raise "fixme"
    csv << [h[:center_x], h[:center_y], h[:background], h[:smooth_factor]]
    csv << [h[:probe_set_name], h[:detection], h[:detection_p_value], h[:signal]]
  end
end

# The CEL file stores the results of the intensity calculations on the pixel
# values of the DAT file. This includes an intensity value, standard deviation
# of the intensity, the number of pixels used to calculate the intensity
# value, a flag to indicate an outlier as calculated by the algorithm and a
# user defined flag indicating the feature should be excluded from future
# analysis. The file stores the previously stated data for each feature on the
# probe array
#
#
# FIXME!
class CEL < CCGeneric
  def initialize(args)
    super(args)
    read_header
    read_data_groups
    read_data_sets
  end

  private
  
  def read_data_row(f, data_set_header)
    if data_set_header[:data_set_name] == "Intensity" then
      # puts "here #{f.tell}"
      h = { :intensity => read_float(f) }
    elsif data_set_header[:data_set_name] == "StdDev" then
      h = { :stddev => read_float(f) }
    elsif data_set_header[:data_set_name] == "Pixel" then
      h = { :pixel => read_ushort(f) }
    elsif data_set_header[:data_set_name] == "Outlier" then
      h = { :outlier => read_ushort(f) }
    elsif data_set_header[:data_set_name] == "Mask" then
      h = { :mask => read_ushort(f) }
    else
      raise "Bad :data_set_name #{data_set_header[:data_set_name]}"
    end
  end

  
  def print_data_row(h, i)
    pretty_print_hash(h, "Row #{i}")
  end

  def write_data_row(h, csv)
    # csv << [h[:probe_set_name], h[:call]]
  end
  
end
