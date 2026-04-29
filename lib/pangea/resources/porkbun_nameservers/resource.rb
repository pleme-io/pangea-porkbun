# frozen_string_literal: true
# Hand-rolled stub. Single resource: porkbun_nameservers — drives
# delegation of a Porkbun-registered domain at an external authoritative
# nameserver set. Future regenerations will replace this file with
# pangea-forge output.

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/porkbun_nameservers/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module PorkbunNameservers
    include Pangea::Resources::ResourceBuilder

    define_resource :porkbun_nameservers,
      attributes_class: Porkbun::Types::NameserversAttributes,
      outputs: { id: :id },
      map: [:domain, :nameservers]
  end
  module Porkbun
    include PorkbunNameservers
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Porkbun)
