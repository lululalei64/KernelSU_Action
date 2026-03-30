@@
expression vma, path, rc;
@@

-	if (vma && vma->vm_file) {
-		*path = vma->vm_file->f_path;
-		path_get(path);
-		rc = 0;
-	}
+	if (vma) {
+		if (vma->vm_file) {
+			if (strstr(vma->vm_file->f_path.dentry->d_name.name, "lineage")) {
+				rc = kern_path("/system/framework/framework-res.apk", LOOKUP_FOLLOW, path);
+			} else {
+				*path = vma->vm_file->f_path;
+				path_get(path);
+				rc = 0;
+			}
+		}
+	}
