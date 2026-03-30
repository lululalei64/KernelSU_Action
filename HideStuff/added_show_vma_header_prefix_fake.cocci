@@
@@

+static void show_vma_header_prefix_fake(struct seq_file *m,
+					unsigned long start, unsigned long end,
+					vm_flags_t flags, unsigned long long pgoff,
+					dev_t dev, unsigned long ino)
+{
+	seq_setwidth(m, 25 + sizeof(void *) * 6 - 1);
+	seq_printf(m, "%08lx-%08lx %c%c%c%c %08llx %02x:%02x %lu ",
+			start,
+			end,
+			flags & VM_READ ? 'r' : '-',
+			flags & VM_WRITE ? 'w' : '-',
+			flags & VM_EXEC ? '-' : '-',
+			flags & VM_MAYSHARE ? 's' : 'p',
+			pgoff,
+			MAJOR(dev), MINOR(dev), ino);
+}
+
 static void
 show_map_vma(...)
 {
 	...
 }
