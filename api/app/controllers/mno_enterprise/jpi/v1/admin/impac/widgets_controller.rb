module MnoEnterprise
  # From the Admin panel, an admin can:
  # - add widgets to template dashboards (passing the dashboard template id)
  # - update any widget (passing its id)
  # - delete any widget (passing its id)
  class Jpi::V1::Admin::Impac::WidgetsController < Jpi::V1::Admin::BaseResourceController

    # POST /mnoe/jpi/v1/admin/impac/dashboard_templates/:id/widgets
    def create
      return render json: { errors: { message: 'Dashboard template not found' } }, status: :not_found unless template.present?

      @widget = template.widgets.create(widget_create_params)
      return render json: { errors: widget&.errors }, status: :bad_request unless widget&.valid?

      MnoEnterprise::EventLogger.info('widget_create', current_user.id, 'Template Widget Creation', widget)
      @no_content = true
      render 'show'
    end

    # PUT /mnoe/jpi/v1/admin/impac/widgets/:id
    def update
      widget.update(widget_update_params)
      return render json: { errors: widget&.errors }, status: :bad_request unless widget&.valid?

      MnoEnterprise::EventLogger.info('widget_update', current_user.id, 'Template Widget Update', widget)
      @nocontent = !params['metadata']
      render 'show'
    end

    # DELETE /mnoe/jpi/v1/admin/impac/widgets/:id
    def destroy
      return render json: { errors: 'Cannot delete widget' }, status: :bad_request unless widget&.destroy

      MnoEnterprise::EventLogger.info('widget_delete', current_user.id, 'Template Widget Deletion', widget)
      head status: :ok
    end

    private

    def template
      MnoEnterprise::Impac::Dashboard.templates.find(params[:dashboard_template_id].to_i)
    end

    def widget
      @widget ||= MnoEnterprise::Impac::Widget.find(params[:id].to_i)
    end

    def widget_create_params
      params.require(:widget).permit(:endpoint, :name, :width).tap do |whitelisted|
        whitelisted[:settings] = params[:widget][:metadata] || {}
        # TODO: remove when mnohub migrated to new model
        whitelisted[:widget_category] = params[:widget][:endpoint]
      end
      .except(:metadata)
    end

    def widget_update_params
      params.require(:widget).permit(:name, :width).tap do |whitelisted|
        whitelisted[:settings] = params[:widget][:metadata] || {}
      end
      .except(:metadata)
    end
  end
end
