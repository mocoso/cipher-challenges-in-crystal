require "option_parser"

file_to_decode = nil

OptionParser.parse! do |parser|
  parser.banner = "Usage: mac [arguments]"
  parser.on("-f NAME", "--filename NAME", "File to decipher") { |name| file_to_decode = name }
end

if file_to_decode.nil?
  puts "No file provided"
else
  CipherCracker.new.decode_file file_to_decode
end

class CipherCracker
  def decode_file(filename : String)
    decode(File.read(filename))
  end

  def decode_file(filename : Nil)
    raise("No file given")
  end

  def decode(cipher_text)
    simplified_cipher_text = Language.english.split_into_words(cipher_text).uniq.join(" ")
    partial_decipher = cipher_text

    puts "decoding"

    keys = Array(Hash(Char, Char)).new
    keys << Hash(Char, Char).new

    while !partial_decipher.match(/[A-Z]/).nil?
      puts "generating next range of keys: current size: " + keys.size.to_s

      keys = keys.map do |key|
        letter = next_coded_letter_to_decipher(key, simplified_cipher_text)
        if letter
          generate_possible_next_keys(key, letter)
        else
          [key]
        end
      end.
      flatten.
      sort_by do |next_key|
        partial_key_score(next_key, simplified_cipher_text)
      end.reverse

      if keys.size > 10
        keys = keys.first(10)
      end

      if keys.size > 0
        partial_decipher = MonoalphabeticSubstitutionCipher.new(keys.first).decode(cipher_text)
        puts "Current best decoding: " + partial_decipher
      end
    end

    puts "Decoded: " + (plain_text = partial_decipher)
    puts "Number of words matched: " + Language.english.number_of_english_words(plain_text).to_s
  end

  def next_coded_letter_to_decipher(partial_key, cipher_text)
    partial_decipher = MonoalphabeticSubstitutionCipher.new(partial_key).decode(cipher_text)
    remaining_coded_letters = partial_decipher.gsub(/[^A-Z]+/, "")
    letter_frequencies = Hash(Char, Int32).new(0)
    letter_frequencies = remaining_coded_letters.each_char.reduce(letter_frequencies) { |h, c| h[c] += 1; h }
    letter_frequencies.max_by { |k, v| v }.first
  end

  def generate_possible_next_keys(partial_key, next_coded_letter)
    (('a'..'z').to_a - partial_key.values).map { |letter|
      new_key = partial_key.clone
      new_key[next_coded_letter] = letter
      new_key
    }
  end

  def partial_key_score(partial_key, cipher_text)
    partial_decipher = MonoalphabeticSubstitutionCipher.new(partial_key).
      decode(cipher_text)

    word_blocks = Language.english.split_into_words(partial_decipher)
    code_match_regex_part = "[^#{partial_key.values.join()}]"

    score = word_blocks.sum { |word_block|
      if word_block.match(/^[A-Z]+$/)
        0.5
      elsif word_block.match(/^[a-z]+$/)
        if Language.english.is_word?(word_block)
          1
        else
          0
        end
      else
        word_block_matcher = Regex.new "^#{word_block.gsub(/[A-Z]/, code_match_regex_part)}$", Regex::Options::MULTILINE
        Language.english.match_word?(word_block_matcher) ? 0.5 : 0
      end
    }

    score / word_blocks.size.to_f
  end

  def coded_words_from_partial_decipher(partial_decipher)
    Language.english.split_into_words(partial_decipher).select { |w| w.downcase != w }
  end

  def decoded_words_from_partial_decipher(partial_decipher)
    Language.english.split_into_words(partial_decipher).select { |w| w.downcase == w }
  end

  def first_coded_letter(partial_decipher)
    match = /[A-Z]/.match partial_decipher
    if match
      match[0]
    end
  end
end


class MonoalphabeticSubstitutionCipher
  @key : Hash(Char, Char)

  def initialize(key : Hash(String, String))
    @key = Hash(Char, Char).new

    key.each do |k, v|
      @key[k.chars.first] = v.chars.first
    end
  end

  def initialize(key : Hash(Char, Char))
    @key = key
  end

  def decode(cipher_text)
    cipher_text.chars.map { |c| key.fetch(c, c) }.join
  end

  def key
    @key
  end
end


class Language
  @words : Hash(String, Bool)
  @word_list : String

  def self.english
    @@english ||= Language.new("/usr/share/dict/words")
  end

  def initialize(dictionary_file_path : String)
    @words = load_words(dictionary_file_path)
    @word_list = @words.keys.join("\n")
  end

  def word_list
    @word_list
  end

  def words
    @words
  end

  def split_into_words(text)
    text.split(/[^\w']+/)
  end

  def is_word?(word)
    words.has_key?(word)
  end

  def match_word?(regex)
    !word_list.match(regex).nil?
  end

  def number_of_english_words(text)
    text.split(' ').count { |w| is_word?(w) }
  end

  def load_words(file_path)
    word_dict = Hash(String, Bool).new
    File.open(file_path) do |file|
      file.each_line do |line|
        word_dict[line.strip] = true
      end
    end
    raise("Found less than 1000 words in the dictionary file") unless word_dict.keys.size > 1000

    word_dict
  end
end

