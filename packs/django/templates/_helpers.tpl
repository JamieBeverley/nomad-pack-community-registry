[[- /*

# Template Helpers

This file contains Nomad pack template helpers. Any information outside of a
`define` template action is informational and is not rendered, allowing you
to write comments and implementation details about your helper functions here.
Some helper functions are included to get you started.

*/ -]]

[[- /*

## `job_name` helper

This helper demonstrates how to use a variable value or fall back to the pack's
metadata when that value is set to a default of "".

*/ -]]

[[- define "job_name" -]]
[[ coalesce ( var "job_name" .) (meta "pack.name" .) | quote ]]
[[- end -]]

[[- /*

## `region` helper

This helper demonstrates conditional element rendering. If your pack specifies
a variable named "region" and it's set, the region line will render otherwise
it won't.

*/ -]]

[[ define "region" -]]
[[- if var "region" . -]]
  region = "[[ var "region" . ]]"
[[- end -]]
[[- end -]]


[[- /*
## `expand_map` helper
Format maps as key and quoted value pairs.
*/ -]]

[[ define "expand_map" -]]
        [[- range $key, $val := . ]]
        [[ $key ]] = [[ $val | quote ]]
        [[- end ]]
[[- end ]]

[[- /*

## `resources` helper

This helper formats values of object(cpu number, memory number) as a `resources`
block

*/ -]]

[[ define "resources" -]]
[[- $resources := . ]]
      resources {
        cpu    = [[ $resources.cpu ]]
        memory = [[ $resources.memory ]]
      }
[[- end ]]
