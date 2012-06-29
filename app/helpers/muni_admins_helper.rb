module MuniAdminsHelper

  def sortable(column, title = nil)
    title     ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction == 1 ? "asc" : "desc" }" : nil
    direction = column == sort_column && sort_direction == 1 ? -1 : 1
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), { :class => css_class }
  end
end
