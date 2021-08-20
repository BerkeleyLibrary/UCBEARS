# Ideally we'd redirect VIPS logging to our own logger, but there are threading
# issues -- see https://github.com/libvips/ruby-vips/issues/131
ENV['VIPS_WARNING'] = '1'
