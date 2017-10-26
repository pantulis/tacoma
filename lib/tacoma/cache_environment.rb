module CacheEnvironment
  def environment_cache_path
    "#{Dir.home}/.tacoma_current_environment"
  end

  def update_environment_to_cache(environment)
    File.open(environment_cache_path, 'w') { |file| file.write(environment) }
  rescue StandardError
    puts "Cannot write at #{environment_cache_path}"
  end

  def read_environment_from_cache
    str = begin
      File.open(environment_cache_path, &:readline)
    rescue StandardError
      nil
    end
    str
  end
end
