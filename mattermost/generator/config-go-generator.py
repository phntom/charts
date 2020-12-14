import re
import yaml

consts = {
    'DEFAULT_LOCALE': 'en',
    'SAML_SETTINGS_DEFAULT_CANONICAL_ALGORITHM': 'Canonical1.0',
    'USER_AUTH_SERVICE_SAML_TEXT': 'SAML',
    'SAML_SETTINGS_DEFAULT_SIGNATURE_ALGORITHM': 'RSAwithSHA1',
}
structs = {}

type_struct = re.compile(r"^type ([^ ]+) struct \{")
default_by_type = {
    '[]string': [],
    '*string': '',
    '*bool': False,
    '*int64': 0,
    '*int': 0,
}
field = re.compile(r'([^ ]+) +(\*string|\*bool|\*int64|\*int|\[]string) +`.*$')
default_val = re.compile(r's.([^ ]+) = (NewBool|NewString|NewInt64|NewInt)\(([^)]+)\)')
const_map_str = re.compile(r'([A-Z0-9]+_[A-Z_0-9]+) += "([^"]*)"')
const_map_int_bool = re.compile(r'([A-Z0-9]+_[A-Z_0-9]+) += (true|false|[0-9]+)')

with open('config.go') as f:
    current_struct = None

    for line in f:
        line = line.strip()
        match_const_map_str = const_map_str.search(line)
        if match_const_map_str:
            consts[match_const_map_str.group(1)] = match_const_map_str.group(2)
            continue
        match_const_map_bool_int = const_map_int_bool.search(line)
        if match_const_map_bool_int:
            val = match_const_map_bool_int.group(2)
            if val == 'true':
                val = True
            elif val == 'false':
                val = False
            else:
                val = int(val)
            consts[match_const_map_bool_int.group(1)] = val
            continue
        match_type_struct = type_struct.search(line)
        if current_struct is not None:
            match_field = field.search(line)
            if match_field:
                field_name = match_field.group(1)
                if 'DEPRECATED' in field_name:
                    continue
                current_struct[field_name] = default_by_type[match_field.group(2)]
                if current_struct[field_name] is default_by_type['[]string']:
                    current_struct[field_name] = list()
                continue
            match_default_val = default_val.search(line)
            if match_default_val:
                field_name = match_default_val.group(1)
                if 'DEPRECATED' in field_name:
                    continue
                val = match_default_val.group(3)
                if val in consts:
                    val = consts[val]
                if 'Int' in match_default_val.group(2):
                    current_struct[field_name] = int(val)
                elif 'Bool' in match_default_val.group(2):
                    current_struct[field_name] = False if val == 'false' else True
                else:
                    current_struct[field_name] = val.strip('"')
                continue
        if match_type_struct:
            name = match_type_struct.group(1)
            current_struct = {}
            structs[name] = current_struct
            continue

print(yaml.dump({'config': structs}))
