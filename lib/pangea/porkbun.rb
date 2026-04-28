# frozen_string_literal: true

# pangea-porkbun — stub.
#
# The real implementation will provide typed resources for Porkbun
# DNS records, nameservers, and domain configuration via Dry::Struct,
# matching the pattern of pangea-cloudflare / pangea-aws.
#
# Until the real gem lands, this stub satisfies bundle resolution so
# pangea-architectures (which depends on this gem via path) can
# evaluate.
module Pangea
  module Porkbun
    VERSION = "0.1.0"
  end
end
