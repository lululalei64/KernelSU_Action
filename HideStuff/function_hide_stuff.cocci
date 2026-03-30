@@
@@

 pgoff = ...;
+		dentry = file->f_path.dentry;
+		if (dentry) {
+			const char *path = (const char *)dentry->d_name.name;
+			if (strstr(path, "lineage")) {
+				start = vma->vm_start;
+				end = vma->vm_end;
+				show_vma_header_prefix(m, start, end, flags, pgoff, dev, ino);
+				name = "/system/framework/framework-res.apk";
+				goto done;
+			}
+			if (strstr(path, "jit-zygote-cache")) {
+				start = vma->vm_start;
+				end = vma->vm_end;
+				show_vma_header_prefix_fake(m, start, end, flags, pgoff, dev, ino);
+				goto bypass;
+			}
+		}
