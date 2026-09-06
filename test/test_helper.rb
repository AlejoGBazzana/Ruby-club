ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Evitar problemas de concurrencia con SQLite
    parallelize(workers: 1)

    setup do
      Inscripcion.delete_all
      Actividad.delete_all
      ActiveRecord::Base.connection.execute("DELETE FROM deportes_deportistas") rescue nil
      Deportista.delete_all
      Deporte.delete_all
      Socio.delete_all
    end
  end
end
