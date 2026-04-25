module ApplicationHelper
  def sortable(column, title = nil, frame:)
    title ||= column.titleize
    direction = (column == params[:sort] && params[:direction] == "asc") ? "desc" : "asc"
    icon = ""

    if column == params[:sort]
      icon = if params[:direction] == "asc"
              '<svg class="ml-1 w-3 h-3 inline-block" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd"></path>
              </svg>'
      else
              '<svg class="ml-1 w-3 h-3 inline-block" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path>
              </svg>'
      end
    end

    params_to_merge = request.params.except(:controller, :action).merge(sort: column, direction: direction)

    link_to(
      (title + icon.html_safe).html_safe,
      params_to_merge,
      class: "sortable-column flex items-center text-xs font-medium uppercase tracking-wider px-2 py-1 hover:text-indigo-600 #{column == params[:sort] ? 'text-indigo-600' : 'text-gray-500'}",
      data: { turbo_frame: frame }
    )
  end
end
