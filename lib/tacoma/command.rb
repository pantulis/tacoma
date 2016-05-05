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
          return false
        end

        if config[environment]
          @aws_identity_file = config[environment]['aws_identity_file']
          @aws_secret_access_key = config[environment]['aws_secret_access_key']
          @aws_access_key_id = config[environment]['aws_access_key_id']
          @repo = config[environment]['repo']
        end
      end
      
      # Assume there is a ~/.aws/credentials file with a valid format
      def current_environment
        current_filename = File.join(Dir.home, ".aws/credentials")
        File.open(current_filename).each do |line|
          if /aws_access_key_id/ =~ line
            current_access_key_id = line[20..-2] # beware the CRLF
            config = Tool.config
            for key in config.keys
              if config[key]['aws_access_key_id'] == current_access_key_id
                return "#{key}"
              end
            end
          end
        end  
        nil
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

    TOOLS = {fog: '.fog', 
             boto: '.boto', 
             s3cfg: '.s3cfg', 
             route53: '.route53', 
             aws_credentials: '.aws/credentials'}

    desc "version", "Displays current tacoma version"
    def version
      puts "tacoma, version #{Tacoma::VERSION}"
      puts "Configuration templates available for:"
      TOOLS.each do |tool, config_path|
        puts "   #{tool.to_s} => '~/#{config_path}'"
      end
    end

    desc "current", "Displays current loaded tacoma environment"
    def current
      puts Tool.current_environment
      return true
    end
    
    desc "switch ENVIRONMENT", "Prepares AWS config files for the providers. --with-exports will output environment variables"
    option :'with-exports'
    
    def switch(environment)

      if Tool.load_vars(environment)
        @aws_identity_file = Tool.aws_identity_file
        @aws_secret_access_key = Tool.aws_secret_access_key
        @aws_access_key_id = Tool.aws_access_key_id
        @repo = Tool.repo

        # set configurations for tools
        TOOLS.each do |tool, config_path|
          template_path = Pathname.new("#{self.class.source_root}/../template/#{tool}").realpath.to_s
          file_path = File.join(Dir.home, config_path)
          template template_path, file_path, :force => true
        end
        
        system("ssh-add #{@aws_identity_file}")
        if options[:'with-exports']
          puts "export AWS_SECRET_ACCESS_KEY=#{@aws_secret_access_key}"
          puts "export AWS_SECRET_KEY=#{@aws_secret_access_key}"
          puts "export AWS_ACCESS_KEY=#{@aws_access_key_id}"
          puts "export AWS_ACCESS_KEY_ID=#{@aws_access_key_id}"
        end
        return true
      else
        return false
      end
    end

    desc "cd ENVIRONMENT", "Change directory to the project path"
    def cd(environment)
      if switch(environment)
        Dir.chdir `echo #{@repo}`.strip
        puts "Welcome to the tacoma shell"
        shell = ENV['SHELL'].split('/').last
        options =
          case shell
          when 'zsh'
            ''
          else
            '--login'
          end
        system("#{shell} #{options}")
        Process.kill(:SIGQUIT, Process.getpgid(Process.ppid))
      end
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
