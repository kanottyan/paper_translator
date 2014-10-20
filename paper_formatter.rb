# encoding: utf-8

class PaperFormatter

  def initialize(source)
    raise "テキストファイルを指定してください" unless File.extname(source) == ".txt"
    raise "指定されたファイルは存在しません" unless File.exist?(source)
    @source = source

    current_dir, original_name = File.split(@source)
    original_name = File.basename(original_name, ".txt")
    original_name = original_name.split("_")[1..-1].join("_") if original_name.include?("_")
    @formatted_text = File.join(current_dir, "formatted_#{original_name}.txt")
  end

  def execute!
    str = ""

    open(@formatted_text, "w") do |f|
      File.foreach(@source) do |line|
        line = line.gsub("ﬁ", "fi").gsub("ﬂ", "fl").chomp
        str = format_string(line, str)
        f.write(str)
      end
    end
  end

  def output_path
    @formatted_text
  end

  private

  def format_string(str, previous_str="")
    case str
    when /\A[Aa]\s*[Bb]\s*[Ss]\s*[Tt]\s*[Rr]\s*[Aa]\s*[Cc]\s*[Tt]\s*\z/, /\A(\d\.)+\s*([a-zA-z0-9\-]+?\s?)+\z/, /\A[a-zA-z0-9\-]+\z/
      lf = previous_str.length < 2 ? "" : "\n" * (2 - previous_str[-2..-1].count("\n"))
      lf + "#{str}\n\n"
    when /[\s\-–][a-zA-z0-9\-]+?-\z/
      str.chop
    when /[\s\-–][a-zA-z0-9\-]+?[\.\?]\z/
      str + "\n"
    when /[\s\-–][a-zA-z0-9\-]+?,?\z/
      str + " "
    else
      str
    end
  end

end

