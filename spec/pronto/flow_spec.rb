require 'spec_helper'

module Pronto
  describe Flow do
    let(:flow) { Flow.new(patches) }
    let(:patches) { [] }

    describe '#run' do
      subject(:run) { flow.run }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          create_repository

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

        after(:each) { delete_repository }

        let(:patches) { Pronto::Git::Repository.new(repo.path).diff("master") }

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
            expect(run.count).to eql(1)
            expect(run.first.msg).to eql("number This type is incompatible with the expected return type of string")
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
            expect(run.count).to eql(1)

            expected_output = <<-HEREDOC
undefined (too few arguments, expected default/rest parameters) This type is incompatible with number
See: content.js:3
            HEREDOC

            expect(run.first.msg).to eql(expected_output.strip)
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
            expect(run.count).to eql(2)

            expected_output = <<-HEREDOC
undefined (too few arguments, expected default/rest parameters) This type is incompatible with number
See: content.js:3
            HEREDOC

            second_expected_output = <<-HEREDOC
undefined (too few arguments, expected default/rest parameters) This type is incompatible with number
See: second_content.js:3
            HEREDOC

            expect(run.first.msg).to eql(expected_output.strip)
            expect(run.last.msg).to eql(second_expected_output.strip)
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
            expect { run }.to raise_error(JSON::ParserError, /custom flow called/)
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
