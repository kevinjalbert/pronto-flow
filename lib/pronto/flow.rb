require 'pronto'
require 'shellwords'

module Pronto
  class Flow < Runner
    CONFIG_FILE = '.pronto_flow.yml'.freeze
    CONFIG_KEYS = %w(flow_executable cli_options).freeze

    attr_writer :flow_executable, :cli_options

    def initialize(patches, commit = nil)
      super(patches, commit)
      read_config
    end

    def flow_executable
      @flow_executable || 'flow'.freeze
    end

    def cli_options
      "#{@cli_options} --json".strip
    end

    def files
      return [] if @patches.nil?

      @files ||= begin
       @patches
         .select { |patch| patch.additions > 0 }
         .map(&:new_file_full_path)
         .compact
     end
    end

    def patch_line_for_offence(path, lineno)
      patch_node = @patches.find do |patch|
        patch.new_file_full_path.to_s == path
      end

      return if patch_node.nil?

      patch_node.added_lines.find do |patch_line|
        patch_line.new_lineno == lineno
      end
    end

    def read_config
      config_file = File.join(git_repo_path, CONFIG_FILE)
      return unless File.exist?(config_file)
      config = YAML.load_file(config_file)

      CONFIG_KEYS.each do |config_key|
        next unless config[config_key]
        send("#{config_key}=", config[config_key])
      end
    end

    def run
      if files.any?
        messages(run_flow)
      else
        []
      end
    end

    def run_flow
      Dir.chdir(git_repo_path) do
        return JSON.parse(`#{flow_executable} --json`)
      end
    end

    def description_for_error(data, first_line_error_in_patch)
      description = data.map do |item|
        item[:descr]
      end.join(" ")

      see_file_paths = data.map do |item|
        next if item[:path].nil? || item[:path].empty?

        file_path = item[:path].sub(git_repo_path.to_s , "")

        next if file_path == first_line_error_in_patch.patch.delta.new_file[:path]

        "\nSee: #{file_path}:#{item[:line]}"
      end

      description = description + see_file_paths.join("")
    end

    def messages(json_output)
      json_output["errors"].map do |error|
        first_patch_with_error = nil
        files_associated_with_error = []

        data = error["message"].map do |context|
          data = { descr: context["descr"], path: context["path"], line: context["line"] }
        end

        first_line_error_in_patch = data.map do |item|
          patch_line_for_offence(item[:path], item[:line])
        end.compact.first

        next if first_line_error_in_patch.nil?

        description = description_for_error(data, first_line_error_in_patch)

        path = first_line_error_in_patch.patch.delta.new_file[:path]

        level = error["level"].to_sym

        Message.new(path, first_line_error_in_patch, level, description, nil, self.class)
      end
    end

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd)).workdir
    end
  end
end
