module Stronglyboards
  class LockFile

    def initialize(project_file)
      @path = File.dirname(project_file) + '/' + LOCK_FILE_NAME
    end

    def contents
      # Load the lock file containing configuration
      file = File.open(@path, 'r')
      YAML::load(file)
    end

    def update(options)
      puts "Writing lock file at #{@path}"
      File.open(@path, 'w+') do |file|
        file.write(YAML::dump(options))
      end
    end

    def delete
      File.delete(@path)
    end

    def exists?
      File.exists?(@path)
    end

    private

      LOCK_FILE_NAME = 'Stronglyboards.lock'

  end
end