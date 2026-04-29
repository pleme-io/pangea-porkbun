# frozen_string_literal: true

# Canonical dashed entrypoint — matches how every other pangea-*
# provider gem (pangea-core, pangea-aws, …) is required. Both
# `require 'pangea/porkbun'` and `require 'pangea-porkbun'` resolve.

require 'pangea-core'
require 'terraform-synthesizer'

module Pangea; module Resources; module Porkbun; module Types; end; end; end; end

# Resources
require_relative 'pangea/resources/porkbun_nameservers/resource'

# Provider-level aggregator (must follow the per-resource requires)
require_relative 'pangea/resources/porkbun'

# Backwards-compat namespace stub from the original gem skeleton.
require_relative 'pangea/porkbun'
