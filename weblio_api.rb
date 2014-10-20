# encoding: utf-8
require 'mechanize'

module WeblioApi
  class Translator
    attr_reader :pool

    GET_URL = "http://ejje.weblio.jp/"
    CHAR_MAX = 4000
    SLEEP_TIME = 3
    SENTENCE_SPLIT_REG_EXP = /((?<=[a-z0-9)][.?!])|(?<=[a-z0-9][.?!]"))\s+(?="?[A-Z])/

    def initialize
      @agent = Mechanize.new
      @agent.keep_alive = false
      @pool = [""]
    end

    def add_pool(str)
      return if !str.kind_of?(String) || str =~ /\A[\s\t　]*\z/

      if (@pool.last + "\n" + str).length <= CHAR_MAX
        @pool.last << "\n" + str
      else
        @pool += split_str_to_appropriate_length(@pool.pop + "\n" + str)
      end
    end

    def pool_blank?
      @pool == [""]
    end

    def translate(str)
      raise "1度に翻訳可能な文字数を超えています" if str.length > CHAR_MAX
      return [] if str =~ /\A[\s\t　]*\z/

      page = @agent.get(GET_URL)
      form = page.form_with(name: "translate")
      form.originalText = str

      (@agent.submit(form) / "li.translatedTextAreaLn").map do |li|
        (li / "span").inner_html.gsub(/["\s\t]+/, "").gsub(/<br\s?\/?>/, "\n")
      end
    end

    def translate_pool
      return [] if pool_blank?

      result = @pool.map do |str|
        sleep(SLEEP_TIME)
        translate(str)
      end
      @pool = [""]

      result
    end

    private

    def split_str_to_appropriate_length(str)
      texts = [""]

      str.split(SENTENCE_SPLIT_REG_EXP).each do |sentence|
        next if sentence.length > CHAR_MAX
        texts << "" if (texts.last + sentence).length > CHAR_MAX
        texts.last << sentence
      end

      texts
    end
  end
end

if $0 == __FILE__
  sample = <<-EOS
    Future research may focus on measuring the amount of information that is contained within the set of recommended tags.
    It might also be useful to investigate the tag-to-tag correlation.
  EOS

  agent = WeblioApi::Translator.new
  agent.add_pool(sample)
  p agent.translate_pool
end




