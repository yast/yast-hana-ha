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
# Summary: SUSE High Availability Setup for SAP Products: GUI Installation Page
# Authors: Ilya Manyugin <ilya.manyugin@suse.com>

require 'yast'
require 'sap_ha/helpers'
require 'sap_ha_wizard/base_wizard_page'
require 'sap_ha/sap_ha_installation'
Yast.import 'Progress'

module Yast
  # GUI Installation Page
  class GUIInstallationPage
    def set(nodes, titles, tasks)
      @tasks = tasks
      Progress.New(
        'SAP High-Availability Setup',
        '',
        titles.length,
        nodes,
        titles,
        '')
      Progress.SubprogressType(:progress, @tasks.length)
      Progress.SubprogressTitle("")
    end

    def next_node
      Progress.NextStage
      @task_no = -1
      next_task
    end

    def next_task
      @task_no += 1
      Progress.SubprogressValue(@task_no)
      Progress.SubprogressTitle(@tasks[@task_no])
    end

    def unblock
      Progress.Finish
    end
  end
end
