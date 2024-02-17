[[- define "job_name" -]]
[[ coalesce ( var "job_name" .) (meta "pack.name" .) | quote ]]
[[- end -]]

[[ define "region" -]]
[[- if var "region" . -]]
  region = "[[ var "region" . ]]"
[[- end -]]
[[- end -]]


[[- /*
## `expand_map` - format maps as key and quoted value pairs.
*/ -]]
[[ define "expand_map" -]]
        [[- range $key, $val := . ]]
        [[ $key ]] = [[ $val | quote ]]
        [[- end ]]
[[- end ]]

[[- /*

## `resources` - formats values of object(cpu number, memory number) as a
`resources` block
*/ -]]
[[ define "resources" -]]
[[- $resources := . ]]
      resources {
        cpu    = [[ $resources.cpu ]]
        memory = [[ $resources.memory ]]
      }
[[- end ]]
