require 'yaml'
require 'thor'
require 'pathname'


module Tacoma


  
  module Tool
    DEFAULT_AWS_REGION = 'eu-west-1'

    class << self
      attr_accessor :aws_identity_file
      attr_accessor :aws_secret_access_key
      attr_accessor :aws_access_key_id
      attr_accessor :region
      attr_accessor :repo

      include CacheEnvironment 

      def config
        filename = File.join(Dir.home, ".tacoma.yml")
        return YAML::load_file(filename)
      end

      def load_vars(environment)
        return false unless exists?(environment)

        config = Tool.config  
        @aws_identity_file = config[environment]['aws_identity_file']
        @aws_secret_access_key = config[environment]['aws_secret_access_key']
        @aws_access_key_id = config[environment]['aws_access_key_id']
        @region = config[environment]['region'] || DEFAULT_AWS_REGION
        @repo = config[environment]['repo']
        validate_vars
      end
      
      # Assume there is a ~/.aws/credentials file with a valid format
      def current_environment
         read_environment_from_cache
      end

      private

      # shows error message if any attr is missing
      # return false if any attr is missing to exit the program
      def validate_vars
        errors = self.instance_variables.map do |var|
          next unless instance_variable_get(var).to_s.empty?
          "Cannot find #{var} key, check your YAML config file."
        end.compact
        puts errors.join("\n") if errors
        errors.empty?
      end

      def exists?(environment)
        config = Tool.config
        if config.keys.include?(environment) == false
          puts "Cannot find #{environment} key, check your YAML config file"
          return false
        else
          return true
        end
      end
    end
  end

  class Command < Thor

    include Thor::Actions

    include CacheEnvironment  

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
        @region = Tool.region
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
          puts "export AWS_DEFAULT_REGION=#{@region}"
        end
        
        update_environment_to_cache(environment)
        
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
