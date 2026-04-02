#!/bin/bash

FILE="drivers/kernelsu/selinux/sepolicy.c"

START=$(grep -n "struct filename_trans_key key;" "$FILE" | head -1 | cut -d: -f1)
END=$(grep -n "return ebitmap_set_bit.*stypes" "$FILE" | head -1 | cut -d: -f1)

echo "Replacing lines $START to $END"

head -n $((START - 1)) "$FILE" > /tmp/sepolicy_new.c

cat >> /tmp/sepolicy_new.c << 'EOF'
    struct filename_trans key;
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
    return ebitmap_set_bit(&db->filename_trans_ttypes, src->value - 1, 1) == 0;
EOF

tail -n +$((END + 1)) "$FILE" >> /tmp/sepolicy_new.c

cp /tmp/sepolicy_new.c "$FILE"
echo "✅ filename_trans fixed"

# Fix type_val_to_struct
sed -i 's/db->type_val_to_struct,/db->type_val_to_struct_array,/g' "$FILE"
sed -i 's/sizeof(\*db->type_val_to_struct)/sizeof(*db->type_val_to_struct_array)/g' "$FILE"
sed -i 's/db->type_val_to_struct = new_type_val_to_struct;/db->type_val_to_struct_array = new_type_val_to_struct;/g' "$FILE"
sed -i 's/db->type_val_to_struct\[value - 1\] = type;/flex_array_put_ptr(db->type_val_to_struct_array, value - 1, type, GFP_ATOMIC);/g' "$FILE"
sed -i 's/db->sym_val_to_name\[SYM_TYPES\]\[value - 1\] = key;/flex_array_put_ptr(db->sym_val_to_name[SYM_TYPES], value - 1, key, GFP_ATOMIC);/g' "$FILE"

echo "✅ type_val_to_struct fixed"