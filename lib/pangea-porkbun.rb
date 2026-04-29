# frozen_string_literal: true

# Canonical dashed entrypoint — matches how every other pangea-*
# provider gem (pangea-core, pangea-aws, …) is required. Both
# `require 'pangea/porkbun'` and `require 'pangea-porkbun'` resolve.
require_relative 'pangea/porkbun'
