# SPDX-License-Identifier: MIT
# Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL
# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"


}


