class CiBuild < ActiveRecord::Base
  attr_accessible :source_project_id, :source_project,
    :target_project_id, :target_project,
    :merge_request_id,
    :source_sha, :target_sha,
    :user_id, :user,
    :service_id, :service_type,
    :state, :coverage, :trace

  belongs_to :service, polymorphic: true

  belongs_to :target_project, foreign_key: :target_project_id, class_name: Project
  belongs_to :source_project, foreign_key: :source_project_id, class_name: Project

  belongs_to :merge_request,  foreign_key: :merge_request_id,  class_name: MergeRequest

  validates :target_project, presence: true
  validates :target_sha,     presence: true
  validates :user,           presence: true

  state_machine :state, initial: :build do
    event :to_success do
      transition [:build] => :success
    end

    event :to_fail do
      transition [:build] => :fail
    end

    state :build
    state :fail
    state :success
  end

  def run
    configuration = service.configuration

    data, path = {}, ""
    if merge_request_build?
      data = data_to_merge_requst_build
      path = configuration.merge_request_path
    else
      data = data_to_push_build
      path = configuration.push_path
    end

    url = configuration.host + path

    WebHook.post(url, body: data.to_json, headers: { "Content-Type" => "application/json" })
  end

  def data_to_push_build
    {
      build_id:   id,
      target_sha: target_sha,
      source_sha: source_sha,
      target_uri: target_project.url_ro_repo,
      source_uri: source_project.url_ro_repo
    }
  end

  def data_to_merge_requst_build
    {
      build_id:   id,
      target_sha: target_sha,
      source_sha: source_sha,
      target_uri: target_project.url_ro_repo,
      source_uri: source_project.url_ro_repo
    }
  end

  def merge_request_build?
    merge_request.present? && source_project.present? && target_project.presen? && !source_sha.blank? && !target_sha.blank?
  end

  def correct_token?(token)
    true
  end
end
