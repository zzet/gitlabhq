module CiBuildsHelper
  def ci_build_status_class(status)
    case status
    when "success"
      "success"
    when "fail"
      "important"
    when "skipped"
      "info"
    when "build"
      "warning"
    when "aborted"
      "inverse"
    when "unstable"
      "inverse"
    end
  end

  def ci_build_status_image(status)
    case status
    when "success"
      "icon-ok"
    when "fail"
      "icon-remove"
    when "skipped"
      "icon-forward"
    when "build"
      "icon-repeat"
    when "aborted"
      "icon-stop"
    when "unstable"
      "icon-warning-sign"
    end
  end
end
