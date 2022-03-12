require 'rails_helper'

describe BuildInfo do
  describe :as_html_comment do
    let(:comment_re) { /<!--(.*)-->/m }
    let(:build_info) { BuildInfo.build_info }
    let(:test_info) do
      {
        CI: 'true',
        BUILD_TIMESTAMP: '2021-03-22T21:57:07+0000',
        BUILD_URL: 'https://jenkins.lib.berkeley.edu/job/gitlab/job/lap/job/lap%252Fucbears/job/LIT-2266-build-args/1/',
        DOCKER_TAG: 'containers.lib.berkeley.edu/lap/ucbears/lit-2266-build-args:build-1',
        GIT_BRANCH: 'LIT-2266-build-args',
        GIT_COMMIT: 'e2493452b7e6ebe98856fa3aff6b2c8f24063586',
        GIT_URL: 'git@git.lib.berkeley.edu:lap/ucbears.git'
      }.freeze
    end

    before do
      @info_orig = build_info.instance_variable_get(:@info)
      @comment_orig = build_info.instance_variable_get(:@html_comment)

      build_info.instance_variable_set(:@info, test_info)
      build_info.instance_variable_set(:@html_comment, nil)
    end

    after do
      build_info.instance_variable_set(:@info, @info_orig)
      build_info.instance_variable_set(:@html_comment, @comment_orig)
    end

    it 'returns an HTML comment' do
      expect(BuildInfo.as_html_comment).to match(comment_re)
    end

    it 'includes all build info' do
      test_info.each do |k, v|
        expect(BuildInfo.as_html_comment).to include("#{k}: #{v}")
      end
    end

    it 'escapes multiple dashes' do
      doubled = test_info.transform_values { |v| v.gsub('-', '--') }
      build_info.instance_variable_set(:@info, doubled)

      test_info.each do |k, v|
        expected_value = v.gsub('-', '&#45;&#45;')
        expect(BuildInfo.as_html_comment).to include("#{k}: #{expected_value}")
      end
    end

    it 'skips nils' do
      without_ci = test_info.except(:CI)
      build_info.instance_variable_set(:@info, without_ci)
      expect(BuildInfo.as_html_comment).not_to include('CI')
    end
  end
end
