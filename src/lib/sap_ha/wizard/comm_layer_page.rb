# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2016 SUSE Linux GmbH, Nuernberg, Germany.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE Linux GmbH.
#
# ------------------------------------------------------------------------------
#
# Summary: SUSE High Availability Setup for SAP Products: Communication Layer Configuration Page
# Authors: Ilya Manyugin <ilya.manyugin@suse.com>
# Authors: Peter Varkoly <varkoly@suse.com>

require "yast"
require "yast/i18n"
require "sap_ha/helpers"
require "sap_ha/wizard/base_wizard_page"

module SapHA
  module Wizard
    # Communication Layer Configuration Page
    class CommLayerConfigurationPage < BaseWizardPage
      # TODO: upon initialization, simply set as many rings as there are interfaces,
      # putting X.X.0.0 as the bind IP address
      def initialize(model)
        super(model)
        textdomain "hana-ha"
        @my_model = model.cluster
        @page_validator = @my_model.method(:validate_comm_layer)
        @recreate_table = true
      end

      def set_contents
        super
        Yast::Wizard.SetContents(
          _("Communication Layer"),
          base_layout_with_label(
            "Define communication layer's configuration",
            VBox(
              VBox(
                two_widget_hbox(
                  ComboBox(Id(:transport_mode), Opt(:notify, :hstretch), "Transport mode:",
                    ["Unicast", "Multicast"]),
                  ComboBox(Id(:number_of_rings), Opt(:notify, :hstretch),
                    "Number of rings:", ["1", "2"])
                ),
                InputField(Id(:cluster_name), Opt(:hstretch), _("C&luster name:"), ""),
                VBox(
                  MinHeight(4, ReplacePoint(Id(:rp_table), Empty())),
                  PushButton(Id(:edit_ring), _("Edit selected"))
                )
              ),
              ComboBox(Id(:fw_config), Opt(:notify, :hstretch), "Firewall configuration", fw_config_items),
              CheckBox(Id(:enable_csync2), Opt(:hstretch), "Enable c&sync2", false),
              CheckBox(Id(:enable_secauth), Opt(:hstretch),
                "Enable &corosync secure authentication", false)
            )
          ),
          Helpers.load_help("comm_layer"), true, true
        )
      end

      def can_go_next?
        return true if @model.no_validators
        @my_model.validate_comm_layer(:silent)
      end

      def refresh_view
        super
        if @recreate_table
          @recreate_table = false
          Yast::UI.ReplaceWidget(Id(:rp_table), ring_table_widget)
        end
        set_value(:transport_mode, @my_model.transport_mode.to_s.capitalize)
        set_value(:number_of_rings, @my_model.number_of_rings.to_s)
        set_value(:ring_definition_table, @my_model.rings_table, :Items)
        set_value(:cluster_name, @my_model.cluster_name)
        set_value(:enable_csync2, @my_model.enable_csync2)
        set_value(:enable_secauth, @my_model.enable_secauth)
      end

      def update_model
        @my_model.cluster_name = value(:cluster_name)
        @my_model.enable_secauth = value(:enable_secauth)
        @my_model.enable_csync2 = value(:enable_csync2)
        @my_model.fw_config = value(:fw_config)
      end

      def ring_table_widget
        log.debug "--- #{self.class}.#{__callee__} ---"
        Table(
          Id(:ring_definition_table),
          Opt(:keepSorting, :notify, :immediate, :hstretch),
          multicast? ?
            Header(_("Ring"), _("Address"), _("Port"), _("Multicast Address"))
            : Header(_("Ring"), _("Address"), _("Port")),
          []
        )
      end

      def multicast?
        @my_model.transport_mode == :multicast
      end

      def handle_user_input(input, event)
        update_model
        case input
        when :edit_ring
          edit_ring
        when :ring_definition_table
          edit_ring if event["EventReason"] == "Activated"
        when :number_of_rings
          number = Integer(value(:number_of_rings))
          @my_model.number_of_rings = number
          @recreate_table = true
          refresh_view
        when :transport_mode
          @my_model.transport_mode = value(:transport_mode).downcase.to_sym
          @recreate_table = true
          refresh_view
        else
          super
        end
      end

      def edit_ring
        item_id = value(:ring_definition_table)
        values = ring_configuration_popup(@my_model.rings[item_id])
        if !values.nil? && !values.empty?
          @my_model.update_ring(item_id, values)
          refresh_view
        end
      end

      # Returns the ring configuration parameters
      def ring_configuration_popup(ring)
        log.debug "--- #{self.class}.#{__callee__} --- "
        base_popup(
          "Configuration for ring #{ring[:id]}",
          @my_model.method(:ring_validator),
          MinWidth(15, ComboBox(Id(:address), "IP address:",
            [ring[:address]] | @my_model.ring_addresses)),
          MinWidth(5, InputField(Id(:port), "Port number:", ring[:port].to_s)),
          multicast? ?
            MinWidth(15, InputField(Id(:mcast), "Multicast address", ring[:mcast]))
            : Empty()
        )
      end

      def fw_config_items
	[Item(Id("done"),  _("Firewall is configured"), @my_model.fw_config == "done"),
         Item(Id("off"),   _("Turn off Firewall"), @my_model.fw_config == "off"),
         Item(Id("setup"), _("Configure Firewall"), @my_model.fw_config == "setup")]
      end
    end
  end
end
