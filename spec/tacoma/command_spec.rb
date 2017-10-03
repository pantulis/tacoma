# Copyright (c) The Cocktail Experience S.L. (2015)
require 'spec_helper'
include Tacoma::Specs

describe Tacoma::Command do
  subject { Tacoma::Command.new }

  before do
    @real_home = ENV['HOME']
    ENV['HOME'] = Tacoma::SPECS_HOME # ./spec/fixtures/home
  end

  after do
    ENV['HOME'] = @real_home
  end

  describe '#install' do
    let(:output) { capture(:stdout) { subject.install } }

    it 'should not overwrite ~/.tacoma.yml if we already have one' do
      output.must_include '~/.tacoma.yml already present'
    end

    it 'should create ~/.tacoma.yml using the template' do
      FileUtils.rm_rf Tacoma::SPECS_TMP
      ENV['HOME'] = Tacoma::SPECS_TMP
      output.must_match /create .+\.tacoma\.yml/
      assert File.exist?("#{ENV['HOME']}/.tacoma.yml")
    end
  end

  describe '#list' do
    let(:output) { capture(:stdout) { subject.list } }

    it 'lists all AWS environments in the .tacoma.yml file' do
      output.must_equal <<-OUTPUT.gsub(/^ {8}/, '')
        first_project
        second_project
      OUTPUT
    end
  end

  describe '#switch' do
    before do
      FileUtils.rm_rf Tacoma::SPECS_TMP
      ENV['HOME'] = Tacoma::SPECS_TMP
      capture(:stdout) { subject.install }
    end

    it 'creates the config files for the specified environment' do
      capture(:stdout) do
        subject.switch 'my_first_project'
      end.must_match /(?:\s+create .+\n){#{Tacoma::Command::TOOLS.size}}/
      # And we have in .aws/credentials my_first_project's key
      aws_credential_value('aws_access_key_id').must_equal 'YOURACCESSKEYID'
    end

    it 'overwrites the config files for the specified environment' do
      capture(:stdout) do
        subject.switch 'my_first_project'
        subject.switch 'my_second_project'
      end.must_match /(?:\s+force .+\n){#{Tacoma::Command::TOOLS.size}}/
      aws_credential_value('aws_access_key_id').must_equal 'ANOTHERACCESSKEYID'
    end
  end
end
