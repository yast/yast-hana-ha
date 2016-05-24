require 'yast'
require 'erb'
require 'yaml'

require 'sap_ha_configuration/cluster_members.rb'
require 'sap_ha_configuration/communication_layer.rb'
require 'sap_ha_configuration/stonith.rb'
require 'sap_ha_configuration/watchdog.rb'
require 'sap_ha_configuration/hana.rb'

module Yast
  # Exceptions
  class ProductNotFoundException < Exception
  end

  class ScenarioNotFoundException < Exception
  end

  # Scenario Configuration class
  class ScenarioConfiguration
    attr_reader   :product_id,
                  :scenario_name
    attr_accessor :debug,
                  :no_validators,
                  :product_name,
                  :product,
                  :scenario,
                  :scenario_summary,
                  :cluster_members,
                  :communication_layer,
                  :stonith,
                  :watchdog,
                  :hana

    include Yast::Logger
    include Yast::I18n

    def initialize
      @debug = false
      @no_validators = false
      @product_id = nil
      @product_name = nil
      @product = nil
      @scenario_name = nil
      @scenario = nil
      @scenario_summary = nil
      @cluster_members = nil # This depends on the scenario configuration
      @communication_layer = CommunicationLayerConfiguration.new
      @yaml_configuration = load_scenarios
      @stonith = StonithConfiguration.new
      @watchdog = WatchdogConfiguration.new
      @hana = HANAConfiguration.new
    end

    # Product ID setter. Raises an ScenarioNotFoundException if the ID was not found in the YAML file
    # @param [String] value product ID
    def product_id=(value)
      @product_id = value
      product = @yaml_configuration.find do |p|
        p['product'] && p['product'].fetch('id', '') == @product_id
      end
      raise ProductNotFoundException, "Could not find product1 with ID '#{value}'" unless product
      @product = product['product']
      @product_name = @product['string_name']
    end

    # Scenario Name setter. Raises an ScenarioNotFoundException if the name was not found in the YAML file
    # @param [String] value scenario name
    def scenario_name=(value)
      log.info "Selected scenario is '#{value}' for product '#{@product_name}'"
      @scenario_name = value
      @scenario = @product['scenarios'].find { |s| s['name'] == @scenario_name }
      if !@scenario
        log.error("Scenario name '#{@scenario_name}' not found in the scenario list")
        raise ScenarioNotFoundException
      end
      @cluster_members = ClusterMembersConfiguration.new(@scenario['number_of_nodes'])
    end

    def all_scenarios
      @product['scenarios'].map { |s| s['name'] }
    end

    # Generate help string for all scenarios
    def scenarios_help
      (@product['scenarios'].map { |s| s['description'] }).join('<br><br>')
    end

    # Can the cluster be set up?
    def can_install?
      configs = [:@cluster_members, :@communication_layer, :@stonith, :@watchdog]
      case @product_id # TODO: product-specific setups
      when "HANA"
        configs << :@hana
      when "NW" 
        configs << :@nw
      end
      configs.map do |config|
        next unless instance_variable_defined?(config)
        conf = instance_variable_get(config)
        next if conf.nil?
        conf.configured?
      end.all?
    end

    private

    # Load scenarios from the YAML configuration file
    def load_scenarios
      # TODO: check the file path
      YAML.load_file('data/scenarios.yaml')
    end

  end # class ScenarioConfiguration
end # module Yast
