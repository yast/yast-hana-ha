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
# Summary: SUSE High Availability Setup for SAP Products: XML RPC Server Client
# Authors: Ilya Manyugin <ilya.manyugin@suse.com>

require "yast"
require "sap_ha/rpc_server"

module Yast
  # An XML RPC Yast Client
  class SapHARPCClass < Client
    def initialize
      @server = SapHA::RPCServer.new
      at_exit { @server.shutdown }
    end

    def main
      # the following call blocks
      @server.start
      # when .shutdown is called
      @server.close_port
    end
  end

  SapHARPC = SapHARPCClass.new
  SapHARPC.main
end
