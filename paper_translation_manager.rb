# encoding: utf-8
DOCUMENT = <<-EOF

-- DOCUMENT --

# About
  英語で記述された論文など(pdf)を日本語に翻訳する

# Requirement
  * pdftotext -> brew install poppler
  * mechanize -> gem install mechanize

# Usage
  * help    -> ruby paper_translation_manager.rb
  * execute -> ruby paper_translation_manager.rb hoge.pdf

EOF

require 'shellwords'
require './paper_formatter'
require './paper_translator'

class PaperTranslationManager

  def initialize(source)
    raise "PDFファイルを指定してください" unless File.extname(source) == ".pdf"
    raise "指定されたファイルは存在しません" unless File.exist?(source)
    @source = source

    current_dir, original_name = File.split(@source)
    original_name = File.basename(original_name, ".pdf")
    @raw_text = File.join(current_dir, "raw_#{original_name}.txt")
  end

  def run_process!
    # PDFファイルからテキストを抽出
    raise unless system("pdftotext -raw -nopgbrk #{@source.shellescape} #{@raw_text.shellescape}")

    # テキストを整形
    formatter = PaperFormatter.new(@raw_text)
    formatter.execute!
    system("rm #{@raw_text.shellescape}")

    # 日本語に訳す
    formatted_text = formatter.output_path
    translator = PaperTranslator.new(formatted_text)
    translator.execute!
    system("rm #{formatted_text.shellescape}")

    puts "以下に翻訳ファイルを出力しました:\n#{translator.output_path}"
  rescue => e
    puts "エラーが発生しました! 処理を中断します..."
    puts e.backtrace.join("\n")
  end

end

if $0 == __FILE__ && ARGV.size.zero?
  puts DOCUMENT
end

if $0 == __FILE__ && !ARGV.size.zero?
  manager = PaperTranslationManager.new(ARGV.first)
  manager.run_process!
end


