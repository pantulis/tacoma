$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tacoma'
require 'minitest/autorun'

module Tacoma
  SPECS_HOME = File.join(File.dirname(__FILE__), 'fixtures', 'home')
  SPECS_TMP = File.join(File.dirname(__FILE__), 'tmp')

  module Specs
    # Receives "X.Y.Z" and returns "X.Y"
    def mayor_minor(semver_string)
      semver_string[/^\d+\.\d+/]
    end

    def capture(stream)
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure
        eval("$#{stream} = #{stream.upcase}")
      end
      result
    end

    def aws_credentials_file
      File.join(ENV['HOME'], '.aws', 'credentials')
    end

    def aws_credential_value(key)
      File.foreach(aws_credentials_file) do |line|
        if line.match(/#{key} = (?<value>\w+)$/)
          return Regexp.last_match(:value)
        end
      end 
    end
  end
end
