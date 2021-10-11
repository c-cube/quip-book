
all:
	@mdbook build .

watch:
	@mdbook watch .

serve:
	@mdbook serve . --port=3004
