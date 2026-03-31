#!/bin/bash
set -e

FILE="drivers/kernelsu/selinux/sepolicy.c"

python3 - << 'PYEOF'
import sys

with open('drivers/kernelsu/selinux/sepolicy.c', 'r') as f:
    content = f.read()

old1 = """    struct filename_trans_key key;
    key.ttype = tgt->value;
    key.tclass = cls->value;
    key.name = (char *)o;
    struct filename_trans_datum *last = NULL;
    struct filename_trans_datum *trans =
        policydb_filenametr_search(db, &key);
    while (trans) {
        if (ebitmap_get_bit(&trans->stypes, src->value - 1)) {
            // Duplicate, overwrite existing data and return
            trans->otype = def->value;
            return true;
        }
        if (trans->otype == def->value)
            break;
        last = trans;
        trans = trans->next;
    }
    if (trans == NULL) {
        trans = (struct filename_trans_datum *)kcalloc(1 ,sizeof(*trans),
                                   GFP_ATOMIC);
        struct filename_trans_key *new_key =
            (struct filename_trans_key *)kzalloc(sizeof(*new_key),
                                 GFP_ATOMIC);
        *new_key = key;
        new_key->name = kstrdup(key.name, GFP_ATOMIC);
        trans->next = last;
        trans->otype = def->value;
        hashtab_insert(&db->filename_trans, new_key, trans,
                   filenametr_key_params);
    }
    db->compat_filename_trans_count++;
    return ebitmap_set_bit(&trans->stypes, src->value - 1, 1) == 0;"""

new1 = """    struct filename_trans key;
    key.ttype = tgt->value;
    key.tclass = cls->value;
    key.name = (char *)o;
    struct filename_trans_datum *trans = hashtab_search(db->filename_trans, &key);
    if (trans == NULL) {
        trans = (struct filename_trans_datum *)kcalloc(sizeof(*trans), 1, GFP_ATOMIC);
        struct filename_trans *new_key = (struct filename_trans *)kzalloc(sizeof(*new_key), GFP_ATOMIC);
        *new_key = key;
        new_key->name = kstrdup(key.name, GFP_ATOMIC);
        trans->otype = def->value;
        hashtab_insert(db->filename_trans, new_key, trans);
    }
    return ebitmap_set_bit(&db->filename_trans_ttypes, src->value - 1, 1) == 0;"""

content = content.replace(old1, new1)
content = content.replace('db->type_val_to_struct,', 'db->type_val_to_struct_array,')
content = content.replace('sizeof(*db->type_val_to_struct)', 'sizeof(*db->type_val_to_struct_array)')
content = content.replace('db->type_val_to_struct = new_type_val_to_struct;', 'db->type_val_to_struct_array = new_type_val_to_struct;')
content = content.replace('db->type_val_to_struct[value - 1] = type;', 'flex_array_put_ptr(db->type_val_to_struct_array, value - 1, type, GFP_ATOMIC);')

content = content.replace(
    'db->sym_val_to_name[SYM_TYPES][value - 1] = key;',
    'flex_array_put_ptr(db->sym_val_to_name[SYM_TYPES], value - 1, key, GFP_ATOMIC);'
)

with open('drivers/kernelsu/selinux/sepolicy.c', 'w') as f:
    f.write(content)

print("✅ sepolicy.c fixed")
PYEOF