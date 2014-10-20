# encoding: utf-8
require 'mechanize'
require 'forwardable'

module WeblioApi
  # Weblio翻訳を利用して翻訳を行うクラス
  class Translator
    GET_URL = "http://ejje.weblio.jp/"
    STR_MAX_LENGTH = 4000
    SLEEP_TIME = 3

    attr_reader :cache

    def initialize
      @cache = Cache.new
      @agent = Mechanize.new
      @agent.keep_alive = false
    end

    def translate(str)
      raise "1度に翻訳可能な文字数を超えています" if str.length > STR_MAX_LENGTH
      return [] if str =~ /\A[\s\t　]*\z/

      page = @agent.get(GET_URL)
      form = page.form_with(name: "translate")
      form.originalText = str

      (@agent.submit(form) / "li.translatedTextAreaLn").map do |li|
        (li / "span").inner_html.gsub(/["\s\t]+/, "").gsub(/<br\s?\/?>/, "\n")
      end
    end

    def translate_cache
      return [] if @cache.blank?

      result = @cache.map do |str|
        sleep(SLEEP_TIME)
        translate(str)
      end
      @cache.clear!

      result
    end
  end

  # APIの問合せ回数を減らすために翻訳対象の文字列を保存しておくクラス
  class Cache
    extend Forwardable

    SENTENCE_SPLIT_REG_EXP = /((?<=[a-z0-9)][.?!])|(?<=[a-z0-9][.?!]"))\s+(?="?[A-Z])/
    def_delegators :@cache, :map

    def initialize
      @cache = [""]
    end

    def add!(str)
      return if !str.kind_of?(String) || str =~ /\A[\s\t　]*\z/

      if (@cache.last + "\n" + str).length <= Translator::STR_MAX_LENGTH
        @cache.last << "\n" + str
      else
        @cache += split_str_to_appropriate_length(@cache.pop + "\n" + str)
      end
    end

    def blank?
      @cache == [""]
    end

    def clear!
      @cache = [""]
    end

    private

    def split_str_to_appropriate_length(str)
      texts = [""]

      str.split(SENTENCE_SPLIT_REG_EXP).each do |sentence|
        next if sentence.length > Translator::STR_MAX_LENGTH
        texts << "" if (texts.last + sentence).length > Translator::STR_MAX_LENGTH
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

  # キャッシュを使わない場合
  p agent.translate(sample)

  # キャッシュを使う場合
  agent.cache.add!(sample)
  p agent.translate_cache
end




