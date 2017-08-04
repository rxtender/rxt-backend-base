export { {%- for item in items %}{{item.identifier}}{% if not loop.last %},{% endif%} {%- endfor %} };
