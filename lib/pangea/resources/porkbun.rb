# frozen_string_literal: true
# Provider-level aggregator. As more Porkbun resources land in this
# gem, add `include` lines here.

module Pangea
  module Resources
    module Porkbun
      include PorkbunNameservers
    end
  end
end
