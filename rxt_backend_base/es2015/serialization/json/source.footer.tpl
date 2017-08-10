export { {%- for item in items %}{{item.identifier}}, {{item.identifier}}_serialize, {{item.identifier}}_deserialize{% if not loop.last %}, {% endif%} {%- endfor %} };
