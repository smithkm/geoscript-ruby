java_import org.geotools.geometry.jts.GeometryCoordinateSequenceTransformer
java_import org.geotools.referencing.CRS
java_import org.opengis.referencing.crs.CoordinateReferenceSystem
java_import org.geotools.factory.Hints

module GeoScript
  class Projection
    attr_accessor :crs

    def initialize(proj)
      if proj.kind_of? CoordinateReferenceSystem
        @crs = proj
      elsif proj.kind_of? GeoScript::Projection
        @crs = proj.crs
      elsif proj.kind_of? String
        @crs = CRS.decode proj
        
        if @crs.nil?
          @crs = CRS.parseWKT proj
          
          if @crs.nil?
            raise "Unable to determine projection from #{proj}"
          end
        end
      end
    end

    def get_id
      CRS.lookup_identifier(@crs, true).to_s
    end

    def get_wkt
      @crs.to_s
    end

    def get_bounds
      env = CRS.get_envelope @crs
      if env
        min = env.get_minimum
        max = env.get_maximum
        GeoScript::Geom::Bounds.create min.first, min.last, max.first, max.last
      end
    end

    def get_geobounds
      box = CRS.get_geographic_bounding_box @crs
      if box
        GeoScript::Geom::Bounds.create box.west_bound_longitude, box.south_bound_latitude, box.east_bound_longitude, box.north_bound_latitude, 'epsg:4326'
      end
    end

    def transform(obj, dest)
      Hints.put_system_default Hints::FORCE_LONGITUDE_FIRST_AXIS_ORDER, java.lang.Boolean.new(true)
      from_crs = @crs
      to_crs = Projection.new(dest).crs
      transform = CRS.find_math_transform(from_crs, to_crs)

      if obj.kind_of? Array
      else
        geometry_transform = GeometryCoordinateSequenceTransformer.new
        geometry_transform.math_transform = transform
        geometry_transform.transform obj
      end
    end

    def self.reproject(obj, from_crs, to_crs)
      Projection.new(from_crs).transform obj, to_crs
    end
  end
end