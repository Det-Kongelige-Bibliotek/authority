require_dependency "authority/application_controller"

module Authority
   include Authority::Concerns::ModalLayout

   class PeopleController < ApplicationController
     authorize_resource
     before_filter do
       if params['modal'].present?
          self.class.layout  'modal' if params['modal'].present?
          logger.debug("modal is present ")
       else
         self.class.layout  'application'
       end
     end
     before_action :set_person, only: [:show, :edit, :update, :destroy]

     def index
       @people = Authority::Person.all
     end

     def show
     end

     def edit
     end

     def update
       respond_to do |format|
         if @person.update(person_params)
           format.html { redirect_to @person }
         else
           format.html { render :new }
         end
       end
     end

     def new
       @person = Person.new
     end

     def create
       @person = Person.new(person_params)

       respond_to do |format|
         if @person.save
           format.html { redirect_to @person }
           format.json  {render json: {id: @person.id, name: @person._name.force_encoding("UTF-8") } }
         else
           format.html { render :new }
           format.json { render json: @person.errors, status: :unprocessable_entity }
         end
       end
     end

     def destroy
       @person.destroy
       respond_to do |format|
         format.html { redirect_to people_url }
       end
     end

     def viaf
       reader = RDF::Reader.open(params[:url])
       stats = reader.each_statement.to_a

       unless stats.select { |s| s.predicate == 'http://schema.org/givenName' }.empty?
         first_name = stats.select { |s| s.predicate == 'http://schema.org/givenName' }.first.object.value
       end
       unless stats.select { |s| s if s.predicate == 'http://schema.org/familyName' }.empty?
         family_name = stats.select { |s| s if s.predicate == 'http://schema.org/familyName' }.first.object.value
       end
       unless stats.select { |s| s.predicate == 'http://schema.org/alternateName' }.empty?
         alternate_name = stats.select { |s| s.predicate == 'http://schema.org/alternateName' }.first.object.value
       end
       unless stats.map { |s| s if s.predicate == 'http://schema.org/sameAs' and s.object.value.include? 'http://isni.org/isni/' }.all? &:nil?
         isni_uri = stats.map { |s| s if s.predicate == 'http://schema.org/sameAs' and
             s.object.value.include? 'http://isni.org/isni/' }.compact.first.object.value
       end

       json_file = {:first_name => first_name, :family_name => family_name, :alternate_name => alternate_name,
                    :isni_uri => isni_uri}
       render json: json_file.to_json
     end

     private

     def set_person
       @person = ActiveFedora::Base.where(id: URI.unescape(params[:id])).first
     end

     def person_params
       params.require(:person).permit( :_name, :description,
                                       :given_name, :family_name, :additional_name,
                                       :award,
                                       :birth_date, :death_date,
                                       :address, :gender, :job_title, :honorific_prefix, :honorific_suffix,
                                       email: [], same_as_uri:[], alternate_names: [])
     end
   end
end
