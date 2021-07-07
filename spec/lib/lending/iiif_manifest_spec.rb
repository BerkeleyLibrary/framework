require 'rails_helper'
require 'lending'

module Lending
  describe IIIFManifest do
    let(:manifest) do
      IIIFManifest.new(
        title: 'Pamphlet',
        author: 'Canada. Department of Agriculture.',
        dir_path: 'spec/data/lending/final/b11996535_B 3 106 704'
      )
    end

    let(:manifest_url) { 'https://ucbears.example.edu/lending/b11996535_B%203%20106%20704/manifest' }
    let(:img_root_url) { 'https://ucbears.example.edu/iiif/' }

    let(:manifest_json) { File.read('spec/data/lending/samples/b11996535_B 3 106 704/manifest.json') }

    describe :to_json do
      it 'creates a manifest' do
        actual = manifest.to_json(manifest_url, img_root_url)
        expect(actual.strip).to eq(manifest_json.strip)
      end
    end

    describe :to_erb do
      let(:manifest_erb) { File.read('spec/data/lending/final/b11996535_B 3 106 704/manifest.json.erb') }
      it 'can create an ERB' do
        expected = manifest_erb
        actual = manifest.to_erb
        expect(actual.strip).to eq(expected.strip)
      end

      it 'generates an ERB that produces a valid manifest' do
        # local, passed to template via binding
        # noinspection RubyUnusedLocalVariable
        manifest_uri = URI(manifest_url)

        # local, passed to template via binding
        # noinspection RubyUnusedLocalVariable
        image_dir_uri = UCBLIT::Util::URIs.append(img_root_url, ERB::Util.url_encode(manifest.dir_basename))

        actual = ERB.new(manifest_erb).result(binding)
        expect(actual.strip).to eq(manifest_json.strip)
      end
    end
  end
end
