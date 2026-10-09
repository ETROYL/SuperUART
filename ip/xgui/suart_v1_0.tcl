# SPDX-License-Identifier: MIT
# Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL
# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "soft_rst_enable" -parent ${Page_0}
  ipgui::add_param $IPINST -name "soft_rst_pattern" -parent ${Page_0}


}

proc update_PARAM_VALUE.soft_rst_enable { PARAM_VALUE.soft_rst_enable } {
	# Procedure called to update soft_rst_enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.soft_rst_enable { PARAM_VALUE.soft_rst_enable } {
	# Procedure called to validate soft_rst_enable
	return true
}

proc update_PARAM_VALUE.soft_rst_pattern { PARAM_VALUE.soft_rst_pattern } {
	# Procedure called to update soft_rst_pattern when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.soft_rst_pattern { PARAM_VALUE.soft_rst_pattern } {
	# Procedure called to validate soft_rst_pattern
	return true
}


proc update_MODELPARAM_VALUE.soft_rst_enable { MODELPARAM_VALUE.soft_rst_enable PARAM_VALUE.soft_rst_enable } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.soft_rst_enable}] ${MODELPARAM_VALUE.soft_rst_enable}
}

proc update_MODELPARAM_VALUE.soft_rst_pattern { MODELPARAM_VALUE.soft_rst_pattern PARAM_VALUE.soft_rst_pattern } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.soft_rst_pattern}] ${MODELPARAM_VALUE.soft_rst_pattern}
}

