#!/usr/bin/env bash

is_installed() {
    cmd dcmdump
}

install() {
    VER=$(latest DCMTK/dcmtk "DCMTK-$VERSION_RE")
    URL="https://github.com/DCMTK/dcmtk/archive/DCMTK-$VER.tar.gz"
    curl "$URL" | tar xz
    cdir "dcmtk-DCMTK-$VER"
    patch_movescu
    cmake \
        -DBUILD_SHARED_LIBS=1 \
        -DDCMTK_ENABLE_BUILTIN_DICTIONARY=1 \
        -DDCMTK_ENABLE_CXX11=1 \
        .
    make "-j$(nproc)"
    sudo make install
    sudo ldconfig
}

patch_movescu() {  # accept unknown contexts in movescu (aka. promiscuous mode)
patch -p1 <<'EOF'
diff -Naur dcmtk/dcmnet/apps/movescu.cc patch/dcmnet/apps/movescu.cc
--- dcmtk/dcmnet/apps/movescu.cc  2020-03-14 10:54:04.425383817 +0100
+++ patch/dcmnet/apps/movescu.cc  2020-03-14 10:56:57.165816940 +0100
@@ -48,6 +48,12 @@

 #define OFFIS_CONSOLE_APPLICATION "movescu"

+static OFCondition acceptUnknownContextsWithPreferredTransferSyntaxes(
+         T_ASC_Parameters * params,
+         const char* transferSyntaxes[],
+         int transferSyntaxCount,
+         T_ASC_SC_ROLE acceptedRole = ASC_SC_ROLE_DEFAULT);
+
 static OFLogger movescuLogger = OFLog::getLogger("dcmtk.apps." OFFIS_CONSOLE_APPLICATION);

 static char rcsid[] = "$dcmtk: " OFFIS_CONSOLE_APPLICATION " v"
@@ -1245,6 +1251,9 @@
                 (*assoc)->params,
                 dcmAllStorageSOPClassUIDs, numberOfDcmAllStorageSOPClassUIDs,
                 transferSyntaxes, numTransferSyntaxes);
+            /* accept everything not known not to be a storage SOP class */
+            cond = acceptUnknownContextsWithPreferredTransferSyntaxes(
+                (*assoc)->params, transferSyntaxes, numTransferSyntaxes);
         }
     }
     if (cond.good())
@@ -1264,6 +1273,141 @@
     return cond;
 }

+static
+DUL_PRESENTATIONCONTEXT *
+findPresentationContextID(LST_HEAD * head,
+                          T_ASC_PresentationContextID presentationContextID)
+{
+  DUL_PRESENTATIONCONTEXT *pc;
+  LST_HEAD **l;
+  OFBool found = OFFalse;
+
+  if (head == NULL)
+    return NULL;
+
+  l = &head;
+  if (*l == NULL)
+    return NULL;
+
+  pc = OFstatic_cast(DUL_PRESENTATIONCONTEXT *, LST_Head(l));
+  (void)LST_Position(l, OFstatic_cast(LST_NODE *, pc));
+
+  while (pc && !found) {
+    if (pc->presentationContextID == presentationContextID) {
+      found = OFTrue;
+    } else {
+      pc = OFstatic_cast(DUL_PRESENTATIONCONTEXT *, LST_Next(l));
+    }
+  }
+  return pc;
+}
+
+
+/** accept all presenstation contexts for unknown SOP classes,
+ *  i.e. UIDs appearing in the list of abstract syntaxes
+ *  where no corresponding name is defined in the UID dictionary.
+ *  @param params pointer to association parameters structure
+ *  @param transferSyntax transfer syntax to accept
+ *  @param acceptedRole SCU/SCP role to accept
+ */
+static OFCondition acceptUnknownContextsWithTransferSyntax(
+  T_ASC_Parameters * params,
+  const char* transferSyntax,
+  T_ASC_SC_ROLE acceptedRole)
+{
+  OFCondition cond = EC_Normal;
+  int n, i, k;
+  DUL_PRESENTATIONCONTEXT *dpc;
+  T_ASC_PresentationContext pc;
+  OFBool accepted = OFFalse;
+  OFBool abstractOK = OFFalse;
+
+  n = ASC_countPresentationContexts(params);
+  for (i = 0; i < n; i++)
+  {
+    cond = ASC_getPresentationContext(params, i, &pc);
+    if (cond.bad()) return cond;
+    abstractOK = OFFalse;
+    accepted = OFFalse;
+
+    if (dcmFindNameOfUID(pc.abstractSyntax) == NULL)
+    {
+      abstractOK = OFTrue;
+
+      /* check the transfer syntax */
+      for (k = 0; (k < OFstatic_cast(int, pc.transferSyntaxCount)) && !accepted; k++)
+      {
+        if (strcmp(pc.proposedTransferSyntaxes[k], transferSyntax) == 0)
+        {
+          accepted = OFTrue;
+        }
+      }
+    }
+
+    if (accepted)
+    {
+      cond = ASC_acceptPresentationContext(
+        params, pc.presentationContextID,
+        transferSyntax, acceptedRole);
+      if (cond.bad()) return cond;
+    } else {
+      T_ASC_P_ResultReason reason;
+
+      /* do not refuse if already accepted */
+      dpc = findPresentationContextID(params->DULparams.acceptedPresentationContext,
+                                      pc.presentationContextID);
+      if ((dpc == NULL) || ((dpc != NULL) && (dpc->result != ASC_P_ACCEPTANCE)))
+      {
+
+        if (abstractOK) {
+          reason = ASC_P_TRANSFERSYNTAXESNOTSUPPORTED;
+        } else {
+          reason = ASC_P_ABSTRACTSYNTAXNOTSUPPORTED;
+        }
+        /*
+         * If previously this presentation context was refused
+         * because of bad transfer syntax let it stay that way.
+         */
+        if ((dpc != NULL) && (dpc->result == ASC_P_TRANSFERSYNTAXESNOTSUPPORTED))
+          reason = ASC_P_TRANSFERSYNTAXESNOTSUPPORTED;
+
+        cond = ASC_refusePresentationContext(params, pc.presentationContextID, reason);
+        if (cond.bad()) return cond;
+      }
+    }
+  }
+  return EC_Normal;
+}
+
+
+/** accept all presenstation contexts for unknown SOP classes,
+ *  i.e. UIDs appearing in the list of abstract syntaxes
+ *  where no corresponding name is defined in the UID dictionary.
+ *  This method is passed a list of "preferred" transfer syntaxes.
+ *  @param params pointer to association parameters structure
+ *  @param transferSyntax transfer syntax to accept
+ *  @param acceptedRole SCU/SCP role to accept
+ */
+static OFCondition acceptUnknownContextsWithPreferredTransferSyntaxes(
+  T_ASC_Parameters * params,
+  const char* transferSyntaxes[], int transferSyntaxCount,
+  T_ASC_SC_ROLE acceptedRole)
+{
+  OFCondition cond = EC_Normal;
+  /*
+  ** Accept in the order "least wanted" to "most wanted" transfer
+  ** syntax.  Accepting a transfer syntax will override previously
+  ** accepted transfer syntaxes.
+  */
+  for (int i = transferSyntaxCount - 1; i >= 0; i--)
+  {
+    cond = acceptUnknownContextsWithTransferSyntax(params, transferSyntaxes[i], acceptedRole);
+    if (cond.bad()) return cond;
+  }
+  return cond;
+}
+
+
 static OFCondition echoSCP(
     T_ASC_Association *assoc,
     T_DIMSE_Message *msg,
EOF
}
