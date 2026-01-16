[database]
connection = {{ include "nova.helpers.db_url" (tuple . "cell0") }}
