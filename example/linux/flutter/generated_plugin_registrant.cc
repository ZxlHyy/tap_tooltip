//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <tap_tooltip/tap_tooltip_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) tap_tooltip_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "TapTooltipPlugin");
  tap_tooltip_plugin_register_with_registrar(tap_tooltip_registrar);
}
