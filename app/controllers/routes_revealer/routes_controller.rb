module RoutesRevealer
  class RoutesController < ApplicationController
    skip_filter(*_process_action_callbacks.map(&:filter))

    def index
      output = map_routes(Rails.application.routes.routes).flatten.compact.uniq
      render json: output
    end

    private

    def ignore_route?(route_string)
      route_string =~ /(\/[0-9]{3})|(^\/routes)|(^\/rails)/
    end

    def map_routes(routes, prepend='')
      prepend = '' if prepend == '/'
      route_hash_array(routes).map do |route_hash|
        if route_hash[:reqs].include?("::Engine")
          map_routes(Module.const_get(route_hash[:reqs]).routes.routes, route_hash[:path])
        else
          "#{prepend}#{route_hash[:path]}" unless ignore_route?(route_hash[:path])
        end
      end
    end

    def route_hash_array(routes)
      routes.map do |route|
        ActionDispatch::Routing::RouteWrapper.new(route)
      end.map do |route|
        {
          path: route.path.sub('(.:format)', ''),
          verb: route.verb,
          reqs: route.reqs
        }
      end
    end
  end
end
