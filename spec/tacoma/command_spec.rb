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
end
