module CampusSolutions
  class LinkController < CampusSolutionsController

    def get
      render json: CampusSolutions::Link.new.get_url(params['urlId'], params['placeholders'])
    end

  end
end
