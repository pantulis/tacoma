require 'yaml'
require 'thor'
require 'pathname'


module Tacoma
  
  module Tool
    def self.config
      filename = File.join(Dir.home, ".tacoma.yml")
      return YAML::load_file(filename)
    end
    
    def self.switch(environment)
      config = Tool.config
      if config.keys.include?(environment) == false
        puts "Cannot find #{environment} key, check your YAML config file"
        return
      end
      
      puts "export AWS_IDENTITY_FILE=" + config[environment]['aws_identity_file'] if config[environment]['aws_identity_file']
      puts "export AWS_SECRET_ACCESS_KEY=" + config[environment]['aws_secret_access_key'] if config[environment]['aws_secret_access_key']
      puts "export AWS_ACCESS_KEY_ID=" + config[environment]['aws_access_key_id'] if config[environment]['aws_access_key_id']
      puts "export REPO=" + config[environment]['repo'] if config[environment]['repo']

      # run ssh-add for the pem file  
      system("ssh-add #{config[environment]['aws_identity_file']}")
    end

  end
  
  class Command < Thor
    
    include Thor::Actions

    desc "list", "Lists all known AWS environments"
    def list
      Tool.config.keys.each do |key|
        puts key
      end
    end
    
    desc "switch ENVIRONMENT", "Loads AWS environment vars"
    def switch(environment)
      Tool.switch(environment)
    end

    desc "install", "Create a sample ~/.tacoma.yml file"
    def install
      if (File.exists?(File.join(Dir.home, ".tacoma.yml")))
        puts "File ~/.tacoma.yml already present, won't overwrite"
      else
        template_path=Pathname.new("#{self.class.source_root}/../template/tacoma.yml").realpath.to_s
        new_path = File.join(Dir.home, ".tacoma.yml")
        template template_path, new_path
      end
    end

  def self.source_root
    File.dirname(__FILE__)
  end	

  end

end

