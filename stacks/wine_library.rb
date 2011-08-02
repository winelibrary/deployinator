module Deployinator
  module Stacks
    module WineLibrary
      def wine_library_git_repo_url
        "git://github.com/winelibrary/wine_library.git"
      end

      def wine_library_production_version
        # %x{curl http://my-app.com/version.txt}
        %x{curl http://b0nk2.winelibrary.com/REVISION --user deploy:w1n3}.chomp
      end

      def wine_library_staging_version
        # %x{curl http://my-app.com/version.txt}
        %x{curl http://staging.winelibrary.com/REVISION --user wlib:wlib123$}.chomp
      end

      def wine_library_staging_head_build
        # the build version you're about to push
        # %x{git ls-remote #{your_git_repo_url} HEAD | cut -c1-7}.chomp
        %x{git ls-remote git@github.com:winelibrary/wine_library.git staging | cut -c1-7}.chomp
      end

      def wine_library_head_build
        # the build version you're about to push
        # %x{git ls-remote #{your_git_repo_url} HEAD | cut -c1-7}.chomp
        %x{git ls-remote git@github.com:winelibrary/wine_library.git master | cut -c1-7}.chomp
      end

      def wine_library_path
        "/Users/danahern/Sites/wine_library"
      end

      def wine_library_rsync(options={})
        build = wine_library_head_build
        old_build = Version.get_build(wine_library_production_version)
        log_and_stream run_cmd %Q{cd #{wine_library_path} && BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec cap production2 deploy 2>&1}
        log_and_shout(:old_build => old_build, :build => build)#, :send_email => true)
      end

      def wine_library_staging_rsync(options={})
        build = wine_library_staging_head_build
        old_build = Version.get_build(wine_library_staging_version)
        log_and_stream run_cmd %Q{cd #{wine_library_path} && BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec cap staging deploy 2>&1}
        log_and_shout(:old_build => old_build, :build => build, :env => "STAGE")#, :send_email => true)
      end
    end
  end
end
