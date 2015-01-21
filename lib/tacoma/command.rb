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

      if Tool.load_vars(environment)
        @aws_identity_file = Tool.aws_identity_file
        @aws_secret_access_key = Tool.aws_secret_access_key
        @aws_access_key_id = Tool.aws_access_key_id
        @repo = Tool.repo

        # set configurations for tools
        {fog: '.fog', boto: '.boto', s3cfg: '.s3cfg', route53: '.route53'}.each do |tool, config_path|
          template_path = Pathname.new("#{self.class.source_root}/../template/#{tool}").realpath.to_s
          file_path = File.join(Dir.home, config_path)
          template template_path, file_path, :force => true
        end
        system("ssh-add #{@aws_identity_file}")
      end
    end

    desc "cd ENVIRONMENT", "Change directory to the project path"
    def cd(environment)
      switch(environment)
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
