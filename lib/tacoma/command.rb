require 'yaml'
require 'thor'
require 'pathname'


module Tacoma
  
  module Tool
    class << self
      attr_accessor :aws_identity_file
      attr_accessor :aws_secret_access_key
      attr_accessor :aws_access_key_id
      attr_accessor :repo
    
      def config
        filename = File.join(Dir.home, ".tacoma.yml")
        return YAML::load_file(filename)
      end
    
      def load_vars(environment)
        config = Tool.config
        if config.keys.include?(environment) == false
          puts "Cannot find #{environment} key, check your YAML config file"
          return
        end
      
        if config[environment]
          @aws_identity_file = config[environment]['aws_identity_file'] 
          @aws_secret_access_key = config[environment]['aws_secret_access_key']
          @aws_access_key_id = config[environment]['aws_access_key_id'] 
          @repo = config[environment]['repo'] 
        end
      end
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
      
      Tool.load_vars(environment)
      @aws_identity_file = Tool.aws_identity_file
      @aws_secret_access_key = Tool.aws_secret_access_key
      @aws_access_key_id = Tool.aws_access_key_id
      @repo = Tool.repo 
       
      # load fog configuration
      fog_template_path = Pathname.new("#{self.class.source_root}/../template/fog").realpath.to_s
      fog_file_path = File.join(Dir.home,".fog")
      template fog_template_path, fog_file_path, :force => true
      
      system("ssh-add #{@aws_identity_file}")
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

