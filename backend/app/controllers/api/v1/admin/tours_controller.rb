module Api
  module V1
    module Admin
      class ToursController < BaseController
        before_action :set_tour, only: %i[show update destroy]

        def index
          render json: Tour.includes(:tour_category).order(:name).map { |tour| serialize(tour) }
        end

        def show
          render json: serialize(@tour)
        end

        def create
          tour = Tour.new(tour_params)
          if tour.save
            render json: serialize(tour), status: :created
          else
            render json: { errors: tour.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @tour.update(tour_params)
            render json: serialize(@tour)
          else
            render json: { errors: @tour.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @tour.update!(published: false)
          head :no_content
        rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
          render json: { error: "This tour cannot be archived because it is used by an existing booking." }, status: :conflict
        end

        private

        def set_tour
          @tour = Tour.find(params[:id])
        end

        def tour_params
          params.require(:tour).permit(
            :name, :slug, :summary, :description, :image_url, :duration_minutes,
            :price_cents, :currency, :published, :area, :category_key,
            :adult_price_cents, :child_price_cents, :baby_price_label,
            :tour_category_id, included_items: [], excluded_items: [], itinerary: []
          )
        end

        def serialize(tour)
          tour.as_json(only: %i[id name slug summary description image_url duration_minutes price_cents currency published area category_key adult_price_cents child_price_cents baby_price_label included_items excluded_items itinerary])
        end
      end
    end
  end
end
