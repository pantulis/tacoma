# Copyright (c) The Cocktail Experience S.L. (2015)
require 'spec_helper'

describe Tacoma do
  describe 'CHANGELOG' do
    let(:first_line) { File.open('CHANGELOG') {|f| f.readline } }

    # Receives "X.Y.Z" and returns "X.Y"
    def mayor_minor(semver_string)
      semver_string[/^\d+\.\d+/]
    end

    it 'explains at least the improvements done in new minor versions' do
      mayor_minor(first_line).must_equal mayor_minor(Tacoma::VERSION)
    end
  end
end
