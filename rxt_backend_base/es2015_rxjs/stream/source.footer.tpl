
export { {% for stream in streams %}create{{stream.identifier}}Observable{% if not loop.last %}, {% endif%} {% endfor %} };
