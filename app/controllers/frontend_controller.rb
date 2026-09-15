class FrontendController < ApplicationController
  layout "frontend"

  def login
  end

  def actividades
  end

  def actividad_detalle
    @actividad_id = params[:id]
  end

  def mis_inscripciones
  end
end
