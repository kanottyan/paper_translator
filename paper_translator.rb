# encoding: utf-8
require 'shellwords'
require './weblio_api'

class PaperTranslator
  SKIP_CONDITION = [/\A[Aa]\s*[Bb]\s*[Ss]\s*[Tt]\s*[Rr]\s*[Aa]\s*[Cc]\s*[Tt]\s*\z/, /\A(\d\.)+\s*([a-zA-z0-9\-]+?\s?)+\z/, /\A[a-zA-z0-9\-]+\z/]

  def initialize(source)
    raise "テキストファイルを指定してください" unless File.extname(source) == ".txt"
    raise "指定されたファイルは存在しません" unless File.exist?(source)
    @source = source

    @total_line_num = `wc -l #{@source.shellescape} | awk '{print $1}'`.to_i
    @total_line_num += 1 unless @total_line_num.zero?

    current_dir, original_name = File.split(@source)
    original_name = File.basename(original_name, ".txt")
    original_name = original_name.split("_")[1..-1].join("_") if original_name.include?("_")
    @translated_text = File.join(current_dir, "#{original_name}.txt")
  end

  def execute!
    agent = WeblioApi::Translator.new

    open(@translated_text, "w") do |f|
      File.foreach(@source).with_index do |line, i|
        line.chomp!
        print_status(i.to_f / @total_line_num)

        if !SKIP_CONDITION.any?{|c| c === line }
          agent.cache.add!(line)
        elsif agent.cache.blank?
          f.write(line + "\n\n")
        else
          result = agent.translate_cache.map(&:first).join("\n")
          f.write(result + "\n\n" + line + "\n\n")
        end
      end
    end
  end

  def output_path
    @translated_text
  end

  private

  def print_status(finished)
    status = "translation finished: %#.02f %" % (finished * 100)
    printf status
    printf "\e[#{status.length}D"
    STDOUT.flush
  end

end
