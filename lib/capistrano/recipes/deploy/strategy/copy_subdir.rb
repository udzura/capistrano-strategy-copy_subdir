# coding: utf-8
#
require 'capistrano/recipes/deploy/strategy/base'
require 'capistrano/recipes/deploy/strategy/copy'

class Capistrano::Deploy::Strategy::CopySubdir < Capistrano::Deploy::Strategy::Copy
  VERSION = "0.0.1"
  # Obtains a copy of the source code locally (via the #command method),
  # compresses it to a single file, copies that file to all target
  # servers, and uncompresses it on each of them into the deployment
  # directory.
  def deploy!
    if copy_cache
      if File.exists?(copy_cache)
        logger.debug "refreshing local cache to revision #{revision} at #{copy_cache}"
        system(source.sync(revision, copy_cache))
      else
        logger.debug "preparing local cache at #{copy_cache}"
        system(source.checkout(revision, copy_cache))
      end

      # Check the return code of last system command and rollback if not 0
      unless $? == 0
        raise Capistrano::Error, "shell command failed with return code #{$?}"
      end

      FileUtils.mkdir_p(destination)

      logger.debug "copying cache to deployment staging area #{destination}"
      Dir.chdir(copy_cache) do
        queue = Dir.glob("*", File::FNM_DOTMATCH)
        while queue.any?
          item = queue.shift
          name = File.basename(item)

          next if name == "." || name == ".."
          next if copy_exclude.any? { |pattern| File.fnmatch(pattern, item) }

          if File.symlink?(item)
            FileUtils.ln_s(File.readlink(item), File.join(destination, item))
          elsif File.directory?(item)
            queue += Dir.glob("#{item}/*", File::FNM_DOTMATCH)
            FileUtils.mkdir(File.join(destination, item))
          else
            FileUtils.ln(item, File.join(destination, item))
          end
        end
      end
    else
      logger.debug "getting (via #{copy_strategy}) revision #{revision} to #{destination}"
      system(command)

      if copy_exclude.any?
        logger.debug "processing exclusions..."
        if copy_exclude.any?
          copy_exclude.each do |pattern|
            delete_list = Dir.glob(File.join(destination, pattern), File::FNM_DOTMATCH)
            # avoid the /.. trap that deletes the parent directories
            delete_list.delete_if { |dir| dir =~ /\/\.\.$/ }
            FileUtils.rm_rf(delete_list.compact)
          end
        end
      end
    end

    # merge stuffs under specific dirs
    if configuration[:merge_dirs]
      configuration[:merge_dirs].each do |dir, dest|
        from = Pathname.new(destination) + dir
        to = Pathname.new(destination) + dest
        logger.trace "#{from} > #{to}"
        FileUtils.mkdir_p(to)
        FileUtils.cp_r(Dir.glob(from), to)
      end
    end

    # for a rails application in sub directory
    #   set :deploy_subdir, "rails"
    if configuration[:deploy_subdir]
      subdir = configuration[:deploy_subdir]
      logger.trace "deploy subdir #{destination}/#{subdir}"
      Dir.mktmpdir do |dir|
        FileUtils.move("#{destination}/#{subdir}", dir)
        FileUtils.rm_rf destination rescue nil
        FileUtils.move("#{dir}/#{subdir}", "#{destination}")
      end
    end

    File.open(File.join(destination, "REVISION"), "w") { |f| f.puts(revision) }

    logger.trace "compressing #{destination} to #{filename}"
    Dir.chdir(copy_dir) { system(compress(File.basename(destination), File.basename(filename)).join(" ")) }

    distribute!
  ensure
    puts $! if $!
    FileUtils.rm filename rescue nil
    FileUtils.rm_rf destination rescue nil
    FileUtils.rm_rf copy_subdir rescue nil
  end

end
