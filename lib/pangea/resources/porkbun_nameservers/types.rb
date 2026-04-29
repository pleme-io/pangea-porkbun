# frozen_string_literal: true
# Hand-rolled stub matching the marcfrederick/porkbun terraform
# provider's `porkbun_nameservers` resource shape. When pangea-forge
# can target Porkbun, this file gets regenerated from the provider's
# resource catalog.

require 'pangea/resources/base_attributes'

module Pangea::Resources::Porkbun::Types
  include Dry.Types()

  class NameserversAttributes < Pangea::Resources::BaseAttributes
    T = Pangea::Resources::Porkbun::Types

    attribute :domain, T::String
    attribute :nameservers, T::Array.of(T::String)
  end
end
