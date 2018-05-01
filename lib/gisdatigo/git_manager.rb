require 'gisdatigo'
require 'rugged'

module Gisdatigo
  class GitManager
    def initialize
      if self.class.available?
        @repository = Rugged::Repository.new('.')
      else
        STDERR.puts "Git is not available in the system"
      end
    end

    def self.available?
      git_version = `git --version`
      if git_version.nil?
        return false
      else
        return true
      end
    end

    def commit(gem_name)
      if self.has_changes?
        @repository.index.diff.each_delta do |delta|
          if delta.status == :modified
            @repository.index.add(delta.old_file[:path])
          else
            raise RuntimeError.new("Found a git delta which status is different from 'modified':\n\t#{delta.inspect}\n\nPlease ensure that the `git status` output is clear before using gisdatigo.")
          end
        end

        Rugged::Commit.create(
          @repository,
          {
            message: "Auto updated: #{gem_name}",
            parents: [@repository.head.target],
            tree: @repository.head.target.tree.oid
          }
        )
      end
    end

    def has_changes?
      @repository.index.diff.deltas.count > 0
    end

    def reset
      @repository.reset(@repository.head, :hard)
    end
  end
end
