module GithubHelpers


  def handle_pull_request params
    action = params[:action]
    number = params[:number]
    Rails.logger.info "Pull Request #{number} #{action}"
    "Done"
  end


  def handle_commit params
    project_file_changed = false
    commits = params[:commits] # Returns an Array of Hash
    commits = [] if commits.nil?
    commits.each do |commit|
      commit.deep_symbolize_keys!
      Rails.logger.info "GitHub hook for commit #{commit[:url]} with commit message -#{commit[:message]}-"
      modified_files = commit[:modified] # Array of modifield files
      modified_files.each do |file_path|
        next if ProjectService.type_by_filename( file_path ).nil?

        project_file_changed = true
        break
      end
    end

    if project_file_changed == false
      error! "Dependencies did not change.", 400
    end

    project = Project.find_by_id( params[:project_id] )
    if project.nil?
      error! "Project with ID #{params[:project_id]} not found.", 400
    end

    if !project.is_collaborator?( current_user )
      error! "You do not have access to this project!", 400
    end

    message = ''
    branch = params[:ref].to_s.gsub('refs/heads/', '')
    if project.scm_branch.to_s.eql?( branch )
      ProjectUpdateService.update_async project, project.notify_after_api_update
      message = "A background job was triggered to update the project #{project.scm_fullname} (#{project.ids})."
    else
      message = "Project branch is #{project.scm_branch} but branch in payload is #{branch}. As the branches are not matching we will ignore this."
    end
    message
  end


end