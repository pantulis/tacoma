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
