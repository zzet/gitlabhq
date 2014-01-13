class FilterContext < BaseContext
  attr_accessor :current_user, :klass, :params

  def initialize(current_user, klass, params)
    @klass, @current_user, @params = klass, current_user, params
  end

  def execute
    items = by_scope
    items = by_state(items)
    items = by_project(items)
    items = by_search(items)
  end

  private

  def by_scope
    table_name = klass.table_name

    case params[:scope]
    when 'authored' then
      current_user.send(table_name)
    when 'all' then
      klass.of_projects(current_user.authorized_projects.pluck(:id))
    else
      current_user.send("assigned_#{table_name}")
    end
  end

  def by_state(items)
    case params[:status]
    when 'closed'
      items.closed
    when 'all'
      items
    else
      items.opened
    end
  end

  def by_project(items)
    if params[:project_id].present?
      items = items.of_projects(params[:project_id])
    end

    items
  end

  def by_search(items)
    if params[:search].present?
      items = items.search(params[:search])
    end

    items
  end
end
