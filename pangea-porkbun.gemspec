# Minimal gemspec stub.
#
# pangea-porkbun is a Pangea provider gem for Porkbun DNS / domain
# resources. The full implementation (typed Dry::Struct resources +
# RSpec synthesis tests + the auto-generated TOML resource catalog) is
# pending; this stub exists so consumers (notably pangea-architectures)
# can resolve the path-dep at bundle time.
#
# Once the real gem lands, this stub gets replaced by `gem build`'s
# generated gemspec from the proper crate2nix-equivalent (bundix)
# pipeline.
Gem::Specification.new do |spec|
  spec.name          = "pangea-porkbun"
  spec.version       = "0.1.0"
  spec.authors       = ["pleme-io"]
  spec.email         = ["[email protected]"]
  spec.summary       = "Porkbun provider resources for Pangea infrastructure DSL"
  spec.description   = "Typed Pangea resources for Porkbun DNS records, " \
                       "nameservers, and domain settings (stub — real impl pending)."
  spec.homepage      = "https://github.com/pleme-io/pangea-porkbun"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-struct", "~> 1.6"
  spec.add_dependency "dry-types",  "~> 1.7"
end
