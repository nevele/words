# std includes
require 'pathname'
require 'set'

# gem includes
require 'rubygems'
require 'rufus-tokyo'

module Words
  
  class WordnetConnection
    
    SHORT_TO_POS_FILE_TYPE = { 'a' => 'adj', 'r' => 'adv', 'n' => 'noun', 'v' => 'verb' }
    
    attr_reader :connected, :connection_type, :data_path, :wordnet_dir
    
    def initialize(type, path, wordnet_path)
      @data_path = Pathname.new("#{File.dirname(__FILE__)}/../data/wordnet.tct") if type == :tokyo && path == :default
      @data_path = Pathname.new("#{File.dirname(__FILE__)}/../data/index.dmp") if type == :pure && path == :default
      @connection_type = type
      
      if @data_path.exist?
        if @connection_type == :tokyo
          @connection = Rufus::Tokyo::Table.new(@data_path.to_s)
          @connected = true
        elsif @connection_type == :pure
          # open the index is there
          File.open(@data_path,'r') do |file|
            @connection = Marshal.load file.read
          end
          # search for the wordnet files
          if locate_wordnet?(wordnet_path)
            @connected = true
          else
            @connected = false
            raise "Failed to locate the wordnet database. Please ensure it is installed and that if it resides at a custom path that path is given as an argument when constructing the Words object."
          end
        else
          @connected = false
        end
      else
        @connected = false
        raise "Failed to locate the words #{ @connection_type == :pure ? 'index' : 'dataset' } at #{@data_path}. Please insure you have created it using the words gems provided 'build_dataset.rb' command."
      end
      
    end
    
    def close
      @connected = false
      if @connected && connection_type == :tokyo
        connection.close 
      end
      return true
    end
    
    def lemma(term)
      if connection_type == :pure
        raw_lemma = @connection[term]
        { 'lemma' => raw_lemma[0], 'tagsense_counts' => raw_lemma[1], 'synset_ids' => raw_lemma[2]}
      else
        @connection[term]
      end
    end
    
    def synset(synset_id)
      if connection_type == :pure
        pos = synset_id[0,1]      
        File.open(@wordnet_dir + "data.#{SHORT_TO_POS_FILE_TYPE[pos]}","r") do |file|
          file.seek(synset_id[1..-1].to_i)
          data_line, gloss = file.readline.strip.split(" | ")
          data_parts = data_line.split(" ")        
          synset_id, lexical_filenum, synset_type, word_count = pos + data_parts.shift, data_parts.shift, data_parts.shift, data_parts.shift.to_i(16)
          words = Array.new(word_count).map { "#{data_parts.shift}.#{data_parts.shift}" }
          relations = Array.new(data_parts.shift.to_i).map { "#{data_parts.shift}.#{data_parts.shift}.#{data_parts.shift}.#{data_parts.shift}" }
          { "synset_id" => synset_id, "lexical_filenum" => lexical_filenum, "synset_type" => synset_type, "words" => words.join('|'), "relations" => relations.join('|'), "gloss" => gloss.strip }          
        end
      else
        @connection[synset_id]
      end
    end
    
    def locate_wordnet?(base_dirs)
      
      base_dirs = case base_dirs
        when :search
        ['/usr/share/wordnet', '/usr/local/share/wordnet', '/usr/local/WordNet-3.0']
      else
        [ base_dirs ] 
      end
      
      base_dirs.each do |dir|
        ["", "dict"].each do |sub_folder| 
          path = Pathname.new(dir + sub_folder)
          @wordnet_dir = path if (path + "data.noun").exist?
          break if !@wordnet_dir.nil?
        end
      end
      
      return !@wordnet_dir.nil?
      
    end
    
  end
  
  class Relation
    
    RELATION_TO_SYMBOL = { "-c" => :member_of_this_domain_topic, "+" => :derivationally_related_form, "%p" => :part_meronym, "~i" => :instance_hyponym, "@" => :hypernym, 
                    ";r" => :domain_of_synset_region, "!" => :antonym, "#p" => :part_holonym, "%s" => :substance_meronym, ";u" => :domain_of_synset_usage, 
                    "-r" => :member_of_this_domain_region, "#s" => :substance_holonym, "=" => :attribute, "-u" => :member_of_this_domain_usage, ";c" => :domain_of_synset_topic,
                    "%m"=> :member_meronym, "~" => :hyponym, "@i" => :instance_hypernym, "#m" => :member_holonym, "$" => :verb_group, ">" => :cause, "*" => :entailment,
                    "\\" => :pertainym, "<" => :participle_of_verb, "&" => :similar_to, "^" => :see_also }
    SYMBOL_TO_RELATION = RELATION_TO_SYMBOL.invert
    
    def initialize(relation_construct, source_synset, wordnet_connection)
      @wordnet_connection = wordnet_connection
      @symbol, @dest_synset_id, @pos, @source_dest = relation_construct.split('.')
      @dest_synset_id = @pos + @dest_synset_id
      @symbol = RELATION_TO_SYMBOL[@symbol]
      @source_synset = source_synset
    end
    
    def is_semantic?
      @source_dest == "0000"
    end
    
    def source_word
      is_semantic? ? @source_word = nil : @source_word = @source_synset.words[@source_dest[0..1].to_i(16)-1] unless defined? @source_word
      @source_word
    end
    
    def destination_word
      is_semantic? ? @destination_word = nil : @destination_word = destination.words[@source_dest[2..3].to_i(16)-1] unless defined? @destination_word
      @destination_word
    end
    
    def relation_type?(type)
      case 
        when SYMBOL_TO_RELATION.include?(type.to_sym)
        type.to_sym == @symbol
        when RELATION_TO_SYMBOL.include?(pos.to_s)
        POINTER_TO_SYMBOL[type.to_sym] == @symbol
      else
        false
      end
    end
    
    def relation_type
      @symbol
    end
    
    def destination
      @destination = Synset.new @dest_synset_id, @wordnet_connection unless defined? @destination
      @destination
    end
    
    def to_s      
      @to_s = "#{relation_type.to_s.gsub('_', ' ').capitalize} relation between #{@source_synset.synset_id}'s word \"#{source_word}\" and #{@dest_synset_id}'s word \"#{destination_word}\"" if !is_semantic? && !defined?(@to_s) 
      @to_s = "Semantic #{relation_type.to_s.gsub('_', ' ')} relation between #{@source_synset.synset_id} and #{@dest_synset_id}" if  is_semantic? && !defined?(@to_s) 
      @to_s
    end
    
    def inspect
      { :symbol => @symbol, :dest_synset_id => @dest_synset_id, :pos => @pos, :source_dest => @source_dest }.inspect
    end
    
  end
  
  class Synset
    
    SYNSET_TYPE_TO_SYMBOL = {"n" => :noun, "v" => :verb, "a" => :adjective, "r" => :adverb, "s" => :adjective_satallite }
    
    def initialize(synset_id, wordnet_connection)
      @wordnet_connection = wordnet_connection
      @synset_hash = wordnet_connection.synset(synset_id)
      # construct some conveniance menthods for relation type access
      Relation::SYMBOL_TO_RELATION.keys.each do |relation_type|
        self.class.send(:define_method, "#{relation_type}s?") do 
          relations(relation_type).size > 0
        end
        self.class.send(:define_method, "#{relation_type}s") do 
          relations(relation_type)
        end
      end
    end
    
    def synset_type
      SYNSET_TYPE_TO_SYMBOL[@synset_hash["synset_type"]]
    end
    
    def words
      @words = words_with_num.map { |word_with_num| word_with_num[:word] } unless defined? @words
      @words
    end
    
    def size
      words.size
    end
    
    def words_with_num
      @words_with_num = @synset_hash["words"].split('|').map { |word| word_parts = word.split('.'); { :word => word_parts[0].gsub('_', ' '), :num => word_parts[1] } } unless defined? @words_with_num
      @words_with_num
    end
    
    def synset_id
      @synset_hash["synset_id"]
    end
    
    def gloss
      @synset_hash["gloss"]
    end
    
    def inspect
      @synset_hash.inspect
    end
    
    def relations(type = :all)
      @relations = @synset_hash["relations"].split('|').map { |relation| Relation.new(relation, self, @wordnet_connection) } unless defined? @relations
      case 
        when Relation::SYMBOL_TO_RELATION.include?(type.to_sym)
        @relations.select { |relation| relation.relation_type == type.to_sym }
        when Relation::RELATION_TO_SYMBOL.include?(type.to_s)
        @relations.select { |relation| relation.relation_type == Relation::RELATION_TO_SYMBOL[type.to_s] }
      else
        @relations
      end
    end
    
    def to_s
      @to_s = "#{synset_type.to_s.capitalize} including word(s): #{words.map { |word| '"' + word + '"' }.join(', ')} meaning: #{gloss}" unless defined? @to_s
      @to_s
    end
    
  end
  
  class Lemma
    
    POS_TO_SYMBOL = {"n" => :noun, "v" => :verb, "a" => :adjective, "r" => :adverb}
    SYMBOL_TO_POS = POS_TO_SYMBOL.invert
    
    def initialize(raw_lemma, wordnet_connection)
      @wordnet_connection = wordnet_connection
      @lemma_hash = raw_lemma
      # construct some conveniance menthods for relation type access
      SYMBOL_TO_POS.keys.each do |pos|
        self.class.send(:define_method, "#{pos}s?") do 
          synsets(pos).size > 0
        end
        self.class.send(:define_method, "#{pos}s") do 
          synsets(pos)
        end
        self.class.send(:define_method, "#{pos}_ids") do 
          synset_ids(pos)
        end
      end
    end
    
    def tagsense_counts
      @tagsense_counts = @lemma_hash["tagsense_counts"].split('|').map { |count| { POS_TO_SYMBOL[count[0,1]] => count[1..-1].to_i }  } unless defined? @tagsense_counts
      @tagsense_counts
    end
    
    def lemma
      @lemma = @lemma_hash["lemma"].gsub('_', ' ') unless defined? @lemma
      @lemma
    end
    
    def available_pos
      @available_pos = synset_ids.map { |synset_id| POS_TO_SYMBOL[synset_id[0,1]] }.uniq unless defined? @available_pos
      @available_pos
    end
    
    def to_s
      @to_s = [lemma, " " + available_pos.join("/")].join(",") unless defined? @to_s
      @to_s
    end
    
    def synsets(pos = :all)
      synset_ids(pos).map { |synset_id| Synset.new synset_id, @wordnet_connection }
    end
    
    def synset_ids(pos = :all)
      @synset_ids = @lemma_hash["synset_ids"].split('|') unless defined? @synset_ids
      case 
        when SYMBOL_TO_POS.include?(pos.to_sym)
        @synset_ids.select { |synset_id| synset_id[0,1] == SYMBOL_TO_POS[pos.to_sym] }
        when POS_TO_SYMBOL.include?(pos.to_s)
        @synset_ids.select { |synset_id| synset_id[0,1] == pos.to_s }
      else
        @synset_ids
      end
    end
    
    def inspect
      @lemma_hash.inspect
    end
    
    alias word lemma
    alias pos available_pos
    
  end
  
  class Words
    
    @wordnet_connection = nil
    
    def initialize(type = :tokyo, path = :default, wordnet_path = :search)
      @wordnet_connection = WordnetConnection.new(type, path, wordnet_path)
    end
    
    def find(word)
      Lemma.new  @wordnet_connection.lemma(word), @wordnet_connection
    end
    
    def connection_type
      @wordnet_connection.connection_type
    end
    
    def wordnet_dir
      @wordnet_connection.wordnet_dir
    end
    
    def close
      @wordnet_connection.close
    end
    
    def connected
      @wordnet_connection.connected
    end
    
    def to_s
      return "Words not connected" if !connected
      return "Words running in pure mode using wordnet files found at #{wordnet_dir} and index at #{@wordnet_connection.data_path}" if connection_type == :pure
      return "Words running in tokyo mode with dataset at #{@wordnet_connection.data_path}" if connection_type == :tokyo
    end
    
  end
  
end