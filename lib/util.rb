class Object
  def load_yaml(path)
    File.exists?(path) ? YAML.load(IO.read(path)) : {}
  end

  def save_yaml(obj, path)
    File.open(path,'w') do |out|
      YAML.dump(obj, out)
    end
  end

  def ask_user(question, default, quiet = false)
    return default if quiet

    def_str = "[#{default}]" if default
    print "#{question}#{def_str} : "
    answer = STDIN.gets.chomp
    return default if (answer.nil? or answer.strip == '') and default
    return answer
  end
end