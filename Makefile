.PHONY: test nits docs nightly test-clean

all: test nits docs

test:
	cargo insta test --unreferenced=reject

test-clean:
	cargo insta test --unreferenced=delete

nits:
	@rustup component add clippy
	cargo clippy --tests -- -D warnings
	@rustup component add rustfmt
	cargo fmt --check

nightly:
	bash infra/nightly.sh
