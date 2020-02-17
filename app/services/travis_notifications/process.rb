module TravisNotifications
  class Process < Services::Base
    def call(travis_notification)
      if travis_notification.processed?
        raise Error, "Travis Notification #{travis_notification.id} has already been processed."
      end

      branch, status = travis_notification.data.fetch_values('branch', 'status')
      compatible     = status == 0
      compat         = Compat.find(branch)

      compat.update! compatible: compatible
      travis_notification.update! compat: compat

      git = CheckOutGitRepo.call
      if git.branches.remote.any? { |remote_branch| remote_branch.name == branch }
        git.push 'origin', branch, delete: true
      end
      FileUtils.rm_rf git.dir.path

      travis_notification.processed!
    end
  end
end
