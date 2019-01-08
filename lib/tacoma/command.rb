require 'yaml'
require 'thor'
require 'pathname'

module Tacoma
  module Tool
    DEFAULT_AWS_REGION = 'eu-west-1'.freeze

    class << self
      attr_accessor :aws_identity_file
      attr_accessor :aws_secret_access_key
      attr_accessor :aws_access_key_id
      attr_accessor :region
      attr_accessor :repo
      attr_accessor :s3cfg
      attr_accessor :kubernetes_state
      attr_accessor :kubernetes_cluster_name


      include CacheEnvironment

      def config
        filename = File.join(Dir.home, '.tacoma.yml')
        YAML.load_file(filename)
      end

      def load_vars(environment)
        return false unless exists?(environment)

        config = Tool.config
        @aws_identity_file = config[environment]['aws_identity_file']
        @aws_secret_access_key = config[environment]['aws_secret_access_key']
        @aws_access_key_id = config[environment]['aws_access_key_id']
        @region = config[environment]['region'] || DEFAULT_AWS_REGION
        @repo = config[environment]['repo']
        @s3cfg = config[environment]['s3cfg'] || {}
        @kubernetes_state = config[environment]['kubernetes_state']
        @kubernetes_cluster_name = config[environment]['kubernetes_cluster_name'] 
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
        errors = instance_variables.map do |var|
          next unless instance_variable_get(var).to_s.empty?
          "Cannot find #{var} key, check your YAML config file."
        end.compact
        puts errors.join("\n") if errors
        errors.empty?
      end

      def exists?(environment)
        config = Tool.config
        return true if config.keys.include?(environment)
        puts "Cannot find #{environment} key, check your YAML config file"
      end
    end
  end

  class Command < Thor
    include Thor::Actions

    include CacheEnvironment

    desc 'list', 'Lists all known AWS environments'
    def list
      Tool.config.each_key do |key|
        puts key
      end
    end

    TOOLS = { fog: '.fog',
              boto: '.boto',
              s3cfg: '.s3cfg',
              route53: '.route53',
              aws_credentials: '.aws/credentials' }.freeze

    desc 'version', 'Displays current tacoma version'
    def version
      puts "tacoma, version #{Tacoma::VERSION}"
      puts 'Configuration templates available for:'
      TOOLS.each do |tool, config_path|
        puts "   #{tool} => '~/#{config_path}'"
      end
    end

    desc 'current', 'Displays current loaded tacoma environment'
    def current
      puts Tool.current_environment
      true
    end

    desc 'switch ENVIRONMENT', 'Prepares AWS config files for the providers. --with-exports will output environment variables'
    option :'with-exports'

    def switch(environment)
      if Tool.load_vars(environment)
        @aws_identity_file = Tool.aws_identity_file
        @aws_secret_access_key = Tool.aws_secret_access_key
        @aws_access_key_id = Tool.aws_access_key_id
        @region = Tool.region
        @repo = Tool.repo
        @s3cfg = Tool.s3cfg

        # set configurations for tools
        TOOLS.each do |tool, config_path|
          template_path = build_template_path(tool)
          file_path = File.join(Dir.home, config_path)
          template template_path, file_path, force: true
        end

        system("ssh-add #{@aws_identity_file}")
        if options[:'with-exports']
          puts "export AWS_SECRET_ACCESS_KEY=#{@aws_secret_access_key}"
          puts "export AWS_SECRET_KEY=#{@aws_secret_access_key}"
          puts "export AWS_ACCESS_KEY=#{@aws_access_key_id}"
          puts "export AWS_ACCESS_KEY_ID=#{@aws_access_key_id}"
          puts "export AWS_DEFAULT_REGION=#{@region}"
          puts "export NAME=#{@kubernetes_cluster_name}"
          puts "export KOPS_STATE_STORE=#{@kubernetes_state}"
        end

        update_environment_to_cache(environment)

        true
      else
        false
      end
    end

    desc 'cd ENVIRONMENT', 'Change directory to the project path'
    def cd(environment)
      return unless switch(environment)

      Dir.chdir `echo #{@repo}`.strip
      puts 'Welcome to the tacoma shell'
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

    desc 'install', 'Create a sample ~/.tacoma.yml file'
    def install
      if File.exist?(File.join(Dir.home, '.tacoma.yml'))
        puts "File ~/.tacoma.yml already present, won't overwrite"
      else
        template_path = build_template_path('tacoma.yml')
        new_path = File.join(Dir.home, '.tacoma.yml')
        template template_path, new_path
      end
    end

    def self.source_root
      File.dirname(__FILE__)
    end

    # private
    no_commands do
      def build_template_path(template_name)
        Pathname.new(
          "#{self.class.source_root}/../template/#{template_name}"
        ).realpath.to_s
      end
    end
  end
end
