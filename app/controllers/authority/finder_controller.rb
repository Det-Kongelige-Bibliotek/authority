require_dependency "authority/application_controller"

module Authority
  class FinderController < ApplicationController
    def search
      result = map_result(AuthFinder.all_things(params[:term],params[:model]))
      render json:  result
    end

    def get_obj
      result = map_result(AuthFinder.obj(URI.unescape(params[:id])))
      if result.empty?
        render :nothing => true, :status => '404'
      else
        render json: result[0]
      end
    end

    def search_by_same_as_uri
      result = map_result(AuthFinder.search_by_same_as_uri(params[:uri]))
      if result.empty?
        render :nothing => true, :status => '404'
      else
        render json: result[0]
      end
    end

    private

    def map_result(result)
      result = result.map {|doc| { :value => doc['display_value_ssm'].try(:first),:id => doc['id']} }
    end
  end
end