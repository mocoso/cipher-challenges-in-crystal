require "spec"
require "../mac.cr"

describe CipherCracker do
  subject = CipherCracker.new

  describe "partial_key_score" do
    partial_key = { 'A' => 'd', 'B' => 'o', 'C' => 'g', 'D' => 'e' }

    it "all words are deciphered and are common words" do
      subject.partial_key_score(partial_key, "ABC").
        should eq 2.0
    end

    it "all words are deciphered and are dictionary words" do
      subject.partial_key_score(partial_key, "ABCD").
        should eq 1.0
    end

    it "all words are not yet deciphered but could still match words" do
      subject.partial_key_score(partial_key, "CXZ").
        should eq 0.5
    end

    it "all words are deciphered and none are dictionary words" do
      subject.partial_key_score(partial_key, "ACB CAB").
        should eq 0.0
    end

    it "all words are not yet deciphered but already can't match words" do
      subject.partial_key_score(partial_key, "CCZ").
        should eq 0.0
    end

    it "2 words are deciphered words and one could match a word and the other not" do
      subject.partial_key_score(partial_key, "ABC XYZ CCZ CBA").
        should eq 1.125
    end
  end

  describe "decoded_words_from_partial_decipher" do
    it "should return all fully decoded words" do
      subject.decoded_words_from_partial_decipher("QWER Afar dog fwt").
        should eq %w(dog fwt)
    end
  end

  describe "first_coded_letter" do
    it {
      subject.first_coded_letter("fewGTerL").should eq "G"
    }
  end

end

describe MonoalphabeticSubstitutionCipher do
  describe "decode" do
    subject = MonoalphabeticSubstitutionCipher.new({ "A" => "d", "B" => "o", "C" => "g" })

    it { subject.decode("ABC").should eq "dog" }
    it { subject.decode("ABC CBA").should eq "dog god" }
  end
end

describe Language do
  describe "english" do
    describe "number_of_english_words" do
      it { Language.english.number_of_english_words("dog god dgo").should eq 2 }
    end

    describe "split_into_words" do
      it {
        Language.english.split_into_words("The lazy dog, can't be THerE").
          should eq ["The", "lazy", "dog", "can't", "be", "THerE"]
        }
    end

    describe "match_common_word?" do
      it "should find there are 3 letter words starting with a" {
        Language.english.match_common_word?(/^a[^a][^a]$/m).
          should eq true
      }

      it "should not find there are 3 letter words starting with qq" {
        Language.english.match_common_word?(/^qq[^q]$/m).
          should eq false
      }
    end

    describe "match_word?" do
      it "should find there are 3 lette words starting with a" {
        Language.english.match_word?(/^a[^a][^a]$/m).
          should eq true
      }

      it "should not find there are 3 letter words starting with qq" {
        Language.english.match_word?(/^qq[^q]$/m).
          should eq false
      }
    end
  end
end
