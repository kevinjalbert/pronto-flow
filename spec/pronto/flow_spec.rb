require 'spec_helper'

module Pronto
  describe Flow do
    let(:flow) { Flow.new(patches) }
    let(:patches) { [] }

    describe '#cli_options' do
      around(:example) do |example|
        create_repository
        Dir.chdir(repository_dir) do
          example.run
        end
        delete_repository
      end

      context 'with custom cli_options' do
        before(:each) do
          add_to_index('.pronto_flow.yml', "cli_options: '--test option'")
          create_commit
        end

        it 'has custom cli options applied (has --json on end)' do
          expect(flow.cli_options).to eq('--test option --json')
        end
      end

      context 'without custom cli_options' do
        it 'has just --json cli options' do
          expect(flow.cli_options).to eq('--json')
        end
      end
    end

    describe '#run' do
      around(:example) do |example|
        create_repository
        Dir.chdir(repository_dir) do
          example.run
        end
        delete_repository
      end

      let(:patches) { Pronto::Git::Repository.new(repository_dir).diff("master") }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(flow.run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(flow.run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          flow_config = <<-HEREDOC
          HEREDOC

          function_def = <<-HEREDOC
            // @flow
            export default function square(n: number): number {
              return n * n;
            }
          HEREDOC

          function_use = <<-HEREDOC
            // @flow
            import square from "./function"
            square(2);
          HEREDOC

          add_to_index('.flowconfig', flow_config)
          add_to_index('function.js', function_def)
          add_to_index('content.js', function_use)

          create_commit
        end

        context "with error in changed file" do
          before(:each) do
            create_branch("staging", checkout: true)

            updated_function_def = <<-HEREDOC
              // @flow
              export default function square(n: number): string {
                return n;
              }
            HEREDOC

            add_to_index('function.js', updated_function_def)

            create_commit
          end

          it 'returns correct error message with ref to other file contexts' do
            expect(flow.run.count).to eql(1)
            expect(flow.run.first.msg).to eql("number This type is incompatible with the expected return type of string")
          end
        end

        context "with error in non-changed file" do
          before(:each) do
            create_branch("staging", checkout: true)

            updated_function_def= <<-HEREDOC
              // @flow
              export default function square(n: number, n1: number): number {
                return n * n1;
              }
            HEREDOC

            add_to_index('function.js', updated_function_def)

            create_commit
          end

          it 'returns correct error message with ref to other file contexts' do
            expect(flow.run.count).to eql(1)

            expected_output = <<-HEREDOC
undefined (too few arguments, expected default/rest parameters) This type is incompatible with number
See: content.js:3
            HEREDOC

            expect(flow.run.first.msg).to eql(expected_output.strip)
          end
        end

        context "with multiple errors within non-changed file" do
          before(:each) do
            second_function_use = <<-HEREDOC
              // @flow
              import square from "./function"
              square(4);
            HEREDOC

            add_to_index('second_content.js', second_function_use)

            create_commit

            create_branch("staging", checkout: true)

            updated_function_def = <<-HEREDOC
              // @flow
              export default function square(n: number, n1: number): number {
                return n * n1;
              }
            HEREDOC

            add_to_index('function.js', updated_function_def)

            create_commit
          end

          it 'returns correct error message with ref to other file contexts' do
            expect(flow.run.count).to eql(2)

            expected_output = <<-HEREDOC
undefined (too few arguments, expected default/rest parameters) This type is incompatible with number
See: content.js:3
            HEREDOC

            second_expected_output = <<-HEREDOC
undefined (too few arguments, expected default/rest parameters) This type is incompatible with number
See: second_content.js:3
            HEREDOC

            expect(flow.run.first.msg).to eql(expected_output.strip)
            expect(flow.run.last.msg).to eql(second_expected_output.strip)
          end
        end

        context "with custom flow_executable" do
          before(:each) do
            create_branch("staging", checkout: true)

            updated_function_use = <<-HEREDOC
              // @flow
              export default function square(n: number, n1: number): number {
                return n * n1;
              }
            HEREDOC

            add_to_index('.pronto_flow.yml', "flow_executable: './custom_flow'")
            add_to_index('custom_flow', "printf 'custom flow called'")
            add_to_index('function.js', updated_function_use)

            create_commit
          end

          it 'calls the custom flow flow_executable' do
            expect { flow.run }.to raise_error(JSON::ParserError, /custom flow called/)
          end
        end
      end
    end

    describe '#flow_executable' do
      subject(:flow_executable) { flow.flow_executable }

      it 'is `flow` by default' do
        expect(flow_executable).to eql('flow')
      end
    end
  end
end
