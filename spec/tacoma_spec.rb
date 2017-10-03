# Copyright (c) The Cocktail Experience S.L. (2015)
require 'spec_helper'
include Tacoma::Specs

describe Tacoma do
  describe 'CHANGELOG' do
    let(:first_line) { File.open('CHANGELOG') {|f| f.readline } }

    it 'explains at least the improvements done in new minor versions' do
      mayor_minor(first_line).must_equal mayor_minor(Tacoma::VERSION)
    end
  end
end
